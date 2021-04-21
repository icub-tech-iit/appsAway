from xml.dom import minidom
import ruamel.yaml

xmldoc = minidom.parse('demo.xml')
dependencieslist = xmldoc.getElementsByTagName('dependencies')

modulelist = xmldoc.getElementsByTagName('module')
connectionslist = xmldoc.getElementsByTagName('connection')

service_list = []
print("\nModules\n")

index = 0 
service_str = """"""

for m in modulelist:
    name = m.getElementsByTagName('name')
    
    service_list.append(name[0].firstChild.nodeValue)
    service_list[index] += "_"
    service_list[index] += str(index)

    parameters = m.getElementsByTagName('parameters')
    dependencies = m.getElementsByTagName('port')

    moduleCmd = "yarp detect --write; "
    
    for d in dependencies:
        moduleCmd += "yarp wait "
        moduleCmd += d.firstChild.nodeValue
        moduleCmd += "; "
        
    moduleCmd += name[0].firstChild.nodeValue

    if parameters:
        moduleCmd += " " 
        moduleCmd += parameters[0].firstChild.nodeValue
    
    print(moduleCmd)

    service_str += f"""
        {service_list[index]}:
          <<: *yarp-base
          deploy:
            placement:
              constraints: [node.labels.type != head]
            restart_policy:
              condition: on-failure
          command: sh -c "{moduleCmd}"
    """
    index += 1

print("\nConnections\n")

print(service_list[0], service_list[1])
print(f"this is super string {service_list[0]}")

#print(f"this is a {service_list[0]}")
#name[1].firstChild.nodeValue

index = 0
for c in connectionslist:
    fromName = c.getElementsByTagName('from')
    toName = c.getElementsByTagName('to')
    protocol = c.getElementsByTagName('protocol')

    connectionCmd = "yarp detect --write; "

    connectionCmd += "yarp wait "
    connectionCmd += fromName[0].firstChild.nodeValue
    connectionCmd += "; "
    connectionCmd += "yarp wait "
    connectionCmd += toName[0].firstChild.nodeValue
    connectionCmd += "; "

    connectionCmd += "yarp connect "
    connectionCmd += fromName[0].firstChild.nodeValue
    connectionCmd += " "
    connectionCmd += toName[0].firstChild.nodeValue
    connectionCmd += " "
    connectionCmd += protocol[0].firstChild.nodeValue
    
    service_str += f"""
        yconnect_{index}:
          <<: *yarp-base
          deploy:
            restart_policy:
              condition: on-failure
          command: sh -c "{connectionCmd}"
    """
    index += 1
    print(connectionCmd)

service_str += f"""
        visualizer:
          image: dockersamples/visualizer:stable
          ports:
            - "8080:8080"
          volumes:
            - "/var/run/docker.sock:/var/run/docker.sock"
          deploy:
            placement:
              constraints: [node.role == manager]
"""

#print (service_str)

yaml_str = f"""
version: "3.7" 
x-yarp-base: &yarp-base

  image: icubteamcode/superbuild:v2020.05_binaries
  environment:
    - DISPLAY=${{DISPLAY}}
    - QT_X11_NO_MITSHM=1
    - XAUTHORITY=/root/.Xauthority
    - YARP_FORWARD_LOG_ENABLE=1
    - YARP_ROBOT_NAME
  volumes:
    - "/tmp/.X11-unix:/tmp/.X11-unix:rw"
    - "${{XAUTHORITY}}:/root/.Xauthority:rw"
    - "${{YARP_CONF_PATH}}:/root/.config/yarp"
  network_mode: bridge
  privileged: true

services:
    {service_str}
"""
#
    #{service_list[0]}:
    #<<: *yarp-base
    #deploy:
    #  P
with open('data.yml', 'w') as outfile:
    data = ruamel.yaml.round_trip_load(yaml_str, preserve_quotes=True)
    ruamel.yaml.round_trip_dump(data, outfile, explicit_start=False)

#!/usr/bin/python3

from xml.dom import minidom
import ruamel.yaml
import argparse
import os
import errno

# Define list of supported gui

gui_list = ["yarpview", "yarplogger", "yarpviz", "yarpmotorgui", "yarpdataplayer"
            "yarpscope", "yarpmobilebasegui", "yarplaserscannergui", "yarpbatterygui",
            "frameGrabberGui2", "iCubSkinGui", "iCubGui", "iCub_SIM", "skinManagerGui",
            "gzclient", "gazebo"]

# Parse arguments
parser = argparse.ArgumentParser(description='Convert yarpmanager xml to RAPID yaml.')

parser.add_argument('--file', dest='fileName',
                    help='Path to the yarpamanger xml file to be converted')

args = parser.parse_args()

xmldoc = minidom.parse(args.fileName)
dependencieslist = xmldoc.getElementsByTagName('dependencies')

modulelist = xmldoc.getElementsByTagName('module')
connectionslist = xmldoc.getElementsByTagName('connection')

service_list = []

application_name = xmldoc.getElementsByTagName('name')[0].firstChild.nodeValue

index = 0
service_gui_str = """"""
service_str = """
        yserver:
          <<: *yarp-base
          deploy:
            placement:
              constraints: [node.role == manager]
            restart_policy:
              condition: on-failure
          command: sh -c "yarp where | grep 'is available at ip' > /dev/null ; if [ ! $$? -eq 0 ]; then yarpserver --read; fi"
"""

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


    if name[0].firstChild.nodeValue in gui_list:
      service_gui_str += f"""
        {service_list[index]}:
          <<: *yarp-base
          deploy:
            placement:
              constraints: [node.labels.type != head]
            restart_policy:
              condition: on-failure
          command: sh -c "{moduleCmd}"
      """
    else:
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
networks:
  hostnet:
    external: true
    name: host
"""

yaml_str = f"""
version: "3.7"
x-yarp-base: &yarp-base

  image: icubteamcode/superbuild:v2021.02.feat-01_master-stable_binaries
  environment:
    - DISPLAY=${{DISPLAY}}
    - QT_X11_NO_MITSHM=1
    - XAUTHORITY=/root/.Xauthority
    - YARP_FORWARD_LOG_ENABLE=1
    - YARP_ROBOT_NAME
  volumes:
    - "/tmp/.X11-unix:/tmp/.X11-unix:rw"
    - "${{XAUTHORITY}}:/root/.Xauthority:rw"
    - "${{HOME}}/${{YARP_CONF_PATH}}:/root/.config/yarp"
"""

yaml_gui_str = yaml_str

yaml_str += f"""
  networks:
    - hostnet

services:
    {service_str}
"""
if service_gui_str :
  yaml_gui_str += f"""
  ports:
    - "10000:10000"
  network_mode: "host"
  privileged: true

services:
      {service_gui_str}
  """

with open('main.yml', 'w') as outfile:
    data = ruamel.yaml.round_trip_load(yaml_str, preserve_quotes=True)
    ruamel.yaml.round_trip_dump(data, outfile, explicit_start=False)
if service_gui_str :
  with open('composeGui.yml', 'w') as outfile:
      data = ruamel.yaml.round_trip_load(yaml_gui_str, preserve_quotes=True)
      ruamel.yaml.round_trip_dump(data, outfile, explicit_start=False)

filename_ini = "./gui/gui_conf.ini"
if not os.path.exists(os.path.dirname(filename_ini)):
    try:
        os.makedirs(os.path.dirname(filename_ini))
    except OSError as exc: # Guard against race condition
        if exc.errno != errno.EEXIST:
            raise

ini_str = f"""
[setup]
title "{application_name}"

[top options]

[right options]

"""

with open(filename_ini, "w") as f:
    f.write(ini_str)

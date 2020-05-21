# Demos

Here we can find all the available demos. Each demo has its own folder, and contains the necessary `.yml` (YAML) files to run the demo.

In addition to the YAML files, there is also a `gui` folder containing a `gui_conf.ini` file with the instructions for the application GUI. The image to use on the background should be saved in the `images` folder, inside the `gui` folder.

### Example of a demo folder tree (robotGazebo demo)

```bash
├── composeGui.yml
├── composeHead.yml
├── gui
│   ├── gui_conf.ini
│   └── images
│       ├── gazebo-simulator.png
│       └── Icon.ico
└── main.yml
```


## Understanding a YAML file

YAML files contain a structure that docker uses to launch its images. You will need a YAML file for each of the machines you are using in your cluster (e.g.: composeGui.yml will be used in icub-gui machine)

<details>
<summary>Click for code explanation</summary>

```yml
version: "3.8" - **This is the version of compose file to use**

name\_of\_service: &pointer\_to\_service **We can define our own service here (it has to be defined before you run services, below)**
  image: name\_of\_image\_or\_dockerhub\_link:version\_or\_tag - **Here is where you write the docker image name that you want to run.**
  ports:
    - "6379" **Indicate here the ports you want to open for this service**
  environment: **You can define or specify which environment variables will be available inside the container here**
    - ENVIRONMENT\_VARIABLE=VALUE
  volumes:
    - volume\_name:/path/to/directory/or/file **Here we specify if the service is using a volume outside the container, which volume and what files inside that volume**
  networks:
    - hostnet **we can specify the network connection to run the service on**
  deploy: **We can specify the options when running multiple containers from the same image. Only used on Docker Swarm**

services: - **Initialization of the services to run on this (and only this!) machine**

  service1: - **Name of the service - you can use any name that makes sense**
    **You can also define your service here instead**
    image: 
    ports:
    networks:
    deploy:
    volumes:

  service2: - **In case you specify your service before "services:"...**
    <<: \*pointer\_to\_service **Use this to point to your service. The options in your service will be used**

networks: **Here we specify the networks to be used in this application, and configure their options**
  hostnet:
    external: true
    name: host

volumes: **the list of volumes that can be used by the containers is specified here, along with their respective options**
  volume\_name:
```
</details>

Check an example from one of the demos for a working example using YARP. For more details on what options are available check Docker [documentation](https://docs.docker.com/compose/compose-file/) page

## Options for the GUI

Our default GUI application is used to start and stop the demos. In order to configure it properly for your individual demo, you can specify your options in the `gui\_conf.ini` file.

<details>
<summary>Check .ini file structure</summary>

```
[setup] 
title "Name of your application" - **Title that will show in the GUI**

[top options] 
ImageName "images/your\_demo\_image.png" - **path to the image illustrating your demo, to be used as the background image in the GUI**
 
[right options]
radioButton "option" - **The option string is sent directly to the container as an environment variable called APPSAWAY_OPTIONS, make sure your container is ready to process it!!!**
```

We recommend that you include a title and image for your demo. If your demo needs no other options, you can ignore the `right options` section.

</details>

# Demos

Here we can find all the available demos. Each demo has its own folder, and contains the necessary `.yml` (YAML) files to run the demo.

In addition to the YAML files, there is also a `gui` folder containing a `gui_conf.ini` file with the instructions for the application GUI. The image to use on the background should be saved in the `images` folder, inside the `gui` folder.

<details>
<summary>Click for example of a demo folder tree (robotGazebo demo) </summary>

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

</details>


## Understanding a YAML file

YAML files contain a structure that docker uses to launch its images. You will need a YAML file for each of the machines you are using in your cluster (e.g.: composeGui.yml will be used in icub-gui machine)

<details>
<summary>Click for code explanation</summary>

```yml
>This is the version of compose file to use
version: "3.8" 

>We can define our own service here (it has to be defined before you run services, below)
name\_of\_service: &pointer\_to\_service 

>  Here is where you write the docker image name that you want to run.
  image: name\_of\_image\_or\_dockerhub\_link:version\_or\_tag 

>  Indicate here the ports you want to open for this service
  ports:
    - "6379" 

>  You can define or specify which environment variables will be available inside the container here
  environment: 
    - ENVIRONMENT\_VARIABLE=VALUE

>  Here we specify if the service is using a volume outside the container, which volume and what files inside that volume
  volumes:
    - volume\_name:/path/to/directory/or/file 

>  we can specify the network connection to run the service on
  networks:
    - hostnet 

>  We can specify the options when running multiple containers from the same image. Only used on Docker Swarm
  deploy: 

>Initialization of the services to run on this (and only this!) machine
services: 

>  You can also define your service here instead
>  Name of the service - you can use any name that makes sense
  service1: 
    image: 
    ports:
    networks:
    deploy:
    volumes:

>  In case you specify your service before "services:"...
  service2: 
  
>    Use this to point to your service. The options in your service will be used
    <<: \*pointer\_to\_service 

>Here we specify the networks to be used in this application, and configure their options
networks: 
  hostnet:
    external: true
    name: host

>the list of volumes that can be used by the containers is specified here, along with their respective options
volumes: 
  volume\_name:
```
</details>

Check an example from one of the demos for a working example using YARP. For more details on what options are available check Docker [documentation](https://docs.docker.com/compose/compose-file/) page.

### Creating your own demo

To create your own demo, create a fork of this repository.

You should start from the template provided in the demoTemplate folder. **Do not change the options already specified in the template**, they are used to correctly initialize both YARP and the visual interfaces. You can add your own services to the template files. Any application that requires a graphical interface should be included in `composeGui.yml` file, while any device or module running on the robot head should be included in `composeHead.yml` (e.g.: camera devices, yarprobotinterface, etc).

Inside the demoTemplate folder you will find a Docker folder. You should include in this folder the Dockerfile to generate your docker image.


<details>
<summary>Click for template tree </summary>

```bash
.
├── composeGui.yml.template
├── composeHead.yml.template
├── Docker
│   ├── Dockerfile.template
│   └── entrypoint.sh.template
├── gui
│   ├── gui_conf.ini.template
│   └── images
└── main.yml.template
```

</details>


## Options for the GUI

Our default GUI application is used to start and stop the demos. In order to configure it properly for your individual demo, you can specify your options in the `gui\_conf.ini` file.

<details>
<summary>Check .ini file structure</summary>

```
[setup]  
>Title that will show in the GUI
title "Name of your application"

[top options] 
>path to the image illustrating your demo, to be used as the background image in the GUI
ImageName "images/your\_demo\_image.png" 
 
[right options]
>The option string is sent directly to the container as an environment variable called APPSAWAY_OPTIONS, make sure your container is ready to process it!!!
radioButton "option" 
```

We recommend that you include a title and image for your demo. If your demo needs no other options, you can ignore the `right options` section.

</details>

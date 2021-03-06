# appsAway
This repository contains all demos provided in the robot bazaar [website](https://robot-bazaar.iit.it/)

For more information on the individual sections, please consult the corresponding page (available below)


# Repository Structure

## [Demos](https://github.com/icub-tech-iit/appsAway/tree/master/demos)

In this folder we can find all the available demos, in their respective folders. 

<details>
<summary>Click for list of available demos</summary>

```bash
.
├── basicDockerDeploy
├── cameraPanCalib
├── demoTemplate
├── faceAndPoseDetection
├── googleDialog
├── googleSpeechApp
├── googleSpeechProcessing
├── googleVisionAI
├── graspTheBall
├── graspTheBallGazebo
├── graspTheBallNoFT
├── iCubGazeboGrasping
├── robotBaseStartup
├── speechToText
├── startQA
├── superbuildPyTorch
├── superbuildTensorflow
├── textToSpeech
├── yarpBasicDeploy
├── yarpOpenFace
└── robotGazebo

```
</details>


## [Gui](https://github.com/icub-tech-iit/appsAway/tree/master/gui)

Here we have the launch GUI script, along with the installation script.


## [Modules](https://github.com/icub-tech-iit/appsAway/tree/master/modules)

Additional modules that don't belong in any particular demo can be included in this folder.

<details>
<summary>Click for list of available modules</summary>

```bash
.
└── checkRobotInterface
```

</details>

## [Scripts](https://github.com/icub-tech-iit/appsAway/tree/master/scripts)

This folder contains all the scripts that link, launch and stop your demos in the machine cluster.

<details>
<summary>Click for list of all scripts</summary>

```bash
.
├── ansible_setup
│   ├── ansible.cfg
│   ├── hosts.ini
│   ├── Makefile
│   ├── playbook.yml
│   ├── prepare.yml
│   └── setup_hosts_ini.sh
├── appsAway_checkUpdates.sh
├── appsAway_deployCleanup.sh
├── appsAway_endApp.sh
├── appsAway_scriptRunner.sh
├── appsAway_setEnvironment.template.sh
├── appsAway_setupCluster.sh
├── appsAway_startApp.sh
├── appsAway_stopApp.sh
├── cleanDockerObjs.sh
└── start.sh
```

</details>


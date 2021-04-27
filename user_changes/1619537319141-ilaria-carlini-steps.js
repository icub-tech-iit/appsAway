//ilaria-carlini
//&<h3>Field changed in app: <ins>Basic Docker Deployment</ins></h3><ul><li>summary: Docker is a tool designed to make it easier to create, deploy, and run applications by using containers. Containers allow a developer to package up an application with all of the parts it needs, such as libraries and other dependencies, and ship it all out as one package. By doing so, thanks to the container, the developer can rest assured that the application will run on any machine regardless of any customized settings that machine might have that could differ from the machine used for writing and testing the code. This particular image is a clean docker containing all the superbuild pre installed so that the user/developer can go straight to work without dealing with cumbersome installations.<b>\n\nThe docker installation on your machine or cluster of machines is done in an automated way using **Ansible**. Ansible is the simplest way to **automate applications** and IT infrastructures. **Application Deployment + Configuration Management + Continuous Delivery**. The only requirement is that the console machine (your main machine), which will act as a **manager**, must have Ansible installed.\n\nHere is how to install **Ansible** on the various platforms: `sudo apt-get update`, `sudo apt-get install openssh-server`, `sudo apt-get install net-tools`.\n\n#### Ubuntu/Linux:\n\n1. `sudo apt-add-repository -y ppa:ansible/ansible`\n2. `sudo apt-get update`\n3. `sudo apt-get install -y ansible`\n4. `sudo apt-get install openssh-server`\n5. `sudo apt-get install net-tools`\n\n#### MacOS (not supported by all applications):\n\n1. `brew install ansible`\n2. Install docker Desktop from this [link](https://hub.docker.com/editions/community/docker-ce-desktop-mac/)\n3. `brew cask install xquartz`</b></li></ul>
db.steps.update ({_id: ObjectId("5f52487b6de3ecd4c51f19c1")},{$set: {summary: "Docker is a tool designed to make it easier to create, deploy, and run applications by using containers. Containers allow a developer to package up an application with all of the parts it needs, such as libraries and other dependencies, and ship it all out as one package. By doing so, thanks to the container, the developer can rest assured that the application will run on any machine regardless of any customized settings that machine might have that could differ from the machine used for writing and testing the code. This particular image is a clean docker containing all the superbuild pre installed so that the user/developer can go straight to work without dealing with cumbersome installations.\n\nThe docker installation on your machine or cluster of machines is done in an automated way using **Ansible**. Ansible is the simplest way to **automate applications** and IT infrastructures. **Application Deployment + Configuration Management + Continuous Delivery**. The only requirement is that the console machine (your main machine), which will act as a **manager**, must have Ansible installed.\n\nHere is how to install **Ansible** on the various platforms: `sudo apt-get update`, `sudo apt-get install openssh-server`, `sudo apt-get install net-tools`.\n\n#### Ubuntu/Linux:\n\n1. `sudo apt-add-repository -y ppa:ansible/ansible`\n2. `sudo apt-get update`\n3. `sudo apt-get install -y ansible`\n4. `sudo apt-get install openssh-server`\n5. `sudo apt-get install net-tools`\n\n#### MacOS (not supported by all applications):\n\n1. `brew install ansible`\n2. Install docker Desktop from this [link](https://hub.docker.com/editions/community/docker-ce-desktop-mac/)\n3. `brew cask install xquartz`"}});

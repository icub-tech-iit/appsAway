//ilaria-carlini
//&<h3>Field changed in app: <ins>Basic Docker Deployment</ins></h3><ul><li>docker_installation_procedure: The docker installation on your machine or cluster of machines is done in an automated way using <del><b></del><b>**</b>Ansible<del></b></del><b>**</b>. Ansible is the simplest way to <del><b></del><b>**</b>automate applications<del></b></del><b>**</b> and IT infrastructures. <del><b></del><b>**</b>Application Deployment + Configuration Management + Continuous Delivery<del></b></del><b>**</b>. The only requirement is that the console machine (your main machine), which will act as a <del><b></del><b>**</b>manager<del></b></del><b>**</b>, must have Ansible installed.\n\nHere is how to install <del><b></del><b>**</b>Ansible<del></b></del><b>**</b> on the various platforms:<del><h4>Ubu</del><b>\</b>n<del>tu/Li</del><b>\</b>n<del>ux:</h4><ol><li><code</del><b>####</b> <del>class='inline'>sudo apt-add-repository -y ppa:ansible/ansi</del><b>U</b>b<del>le</code></li><li><code class='inline'>s</del>u<del>do apt-get update</code></li><li><code class='i</del>n<del>line'>sudo ap</del>t<del>-get install -y ansible</code></li><li><code class='inline'>s</del>u<del>do apt-get install openssh-server<</del>/<del>code></li><li><code class='inline'>sudo apt-get install net-tools</code></li></ol><h4>MacOS (not supported by all applications):</h4><ol><li><code class='inline'>brew install ansible</code></li><li>Install docker Desktop from this <a href='https://hub.docker.com/editions/community/docker-ce-desktop-mac/'>link</a></li><li><code class='inline'>brew install ansible</code></li><li><code class='inline'>ruby -e $(curl -fsS</del>L<del> https://raw.g</del>i<del>thubusercontent.com/Homebrew/install/master/install) < /dev/</del>nu<del>ll 2> /dev/null ; brew install caskroom/cask/brew-cask 2> /dev/null</code></li><li><code class='inline'>brew cask install </del>x<del>quartz</code></li><li>Once installed, logout and log back in, then add an option to Xquartz</del>:<del> <code class='inline'>open -a Xquartz</code></li></ol></del></li></ul>
db.steps.update ({_id: ObjectId("5f52487b6de3ecd4c51f19c2")},{$set: {docker_installation_procedure: "The docker installation on your machine or cluster of machines is done in an automated way using **Ansible**. Ansible is the simplest way to **automate applications** and IT infrastructures. **Application Deployment + Configuration Management + Continuous Delivery**. The only requirement is that the console machine (your main machine), which will act as a **manager**, must have Ansible installed.\n\nHere is how to install **Ansible** on the various platforms:\n\n#### Ubuntu/Linux:"}});

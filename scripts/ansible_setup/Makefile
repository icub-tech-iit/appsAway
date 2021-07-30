.PHONY: prepare_all
prepare_all:
	ansible-playbook -i hosts.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare_docker.yml
	ansible-playbook -i hosts.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare_compose.yml 
	ansible-playbook -i hosts.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare_cuda.yml  

.PHONY: prepare_docker
prepare_docker:
	ansible-playbook -i hosts_docker.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare_docker.yml 
	ansible-playbook -i hosts_docker.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare_compose.yml 

.PHONY: prepare_compose
prepare_compose:
	ansible-playbook -i hosts_compose.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare_compose.yml 

.PHONY: prepare_cuda
prepare_cuda:
	ansible-playbook -i hosts_cuda.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare_cuda.yml 

.PHONY: cluster
cluster:
	ansible-playbook -K playbook.yml

.PHONY: destroy
destroy:
	ansible-playbook -K destroy.yml
	
.PHONY: prepare_local_registry
prepare_local_registry:
	ansible-playbook -i hosts.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare_local_registry.yml 

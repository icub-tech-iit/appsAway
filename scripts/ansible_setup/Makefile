.PHONY: prepare
prepare:
	ansible-playbook -i hosts.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare.yml 

.PHONY: cluster
cluster:
	ansible-playbook -K playbook.yml

.PHONY: destroy
destroy:
	ansible-playbook -K destroy.yml
	
.PHONY: prepare_local_registry
prepare_local_registry:
	ansible-playbook -i hosts.ini -e @passwords.enc --vault-password-file vault_password_file.txt prepare_local_registry.yml 

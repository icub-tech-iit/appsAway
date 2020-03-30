.PHONY: prepare
prepare:
	ansible-playbook -K prepare.yml

.PHONY: cluster
cluster:
	ansible-playbook -K playbook.yml

.PHONY: destroy
destroy:
	ansible-playbook -K destroy.yml

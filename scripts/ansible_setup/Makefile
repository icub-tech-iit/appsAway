.PHONY: prepare
prepare:
	ansible-playbook prepare.yml

.PHONY: cluster
cluster:
	ansible-playbook -K playbook.yml

.PHONY: destroy
destroy:
	ansible-playbook -K destroy.yml

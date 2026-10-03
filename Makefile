.PHONY: setup ansible-install ansible-inventory ansible-setup ansible-monitoring ansible-deploy deploy tf-vars tf-init tf-plan tf-apply tf-destroy tf-output vault-edit vault-view

# Пароль от Ansible Vault. Переопределяется: make VAULT_PASSWORD_FILE=... <цель>
VAULT_PASSWORD_FILE ?= $(HOME)/.config/hexlet-devops-77/vault_pass
export ANSIBLE_VAULT_PASSWORD_FILE = $(VAULT_PASSWORD_FILE)

setup: ansible-install tf-init

ansible-install:
	cd ansible && ansible-galaxy collection install -r requirements.yml
	cd ansible && ansible-galaxy role install -r requirements.yml

tf-vars:
	cd ansible && ansible-playbook playbook.yml --tags terraform

tf-init: tf-vars
	terraform -chdir=terraform init -backend-config=secrets.backend.tfvars

tf-plan: tf-vars
	terraform -chdir=terraform plan

tf-apply: tf-vars
	terraform -chdir=terraform apply

tf-destroy: tf-vars
	terraform -chdir=terraform destroy

tf-output:
	terraform -chdir=terraform output

vault-edit:
	cd ansible && ansible-vault edit group_vars/all/vault.yml

vault-view:
	cd ansible && ansible-vault view group_vars/all/vault.yml

ansible-inventory:
	cd ansible && ansible-playbook playbook.yml --tags inventory

ansible-setup:
	cd ansible && ansible-playbook playbook.yml --tags setup

ansible-monitoring:
	cd ansible && ansible-playbook playbook.yml --tags monitoring

ansible-deploy:
	cd ansible && ansible-playbook playbook.yml --tags deploy

deploy: ansible-setup ansible-deploy

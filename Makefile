.PHONY: tf-vars tf-init tf-plan tf-apply tf-destroy vault-edit vault-view

tf-vars:
	cd ansible && ansible-playbook terraform.yml

tf-init: tf-vars
	terraform -chdir=terraform init -backend-config=secrets.backend.tfvars

tf-plan: tf-vars
	terraform -chdir=terraform plan

tf-apply: tf-vars
	terraform -chdir=terraform apply

tf-destroy: tf-vars
	terraform -chdir=terraform destroy

vault-edit:
	cd ansible && ansible-vault edit group_vars/all/vault.yml

vault-view:
	cd ansible && ansible-vault view group_vars/all/vault.yml

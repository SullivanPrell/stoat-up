# Makefile for OCI Deployment

# Load environment variables from .env file
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: all plan apply destroy configure output clean validate

all: configure

plan:
	@echo "Planning Terraform infrastructure..."
	@cd terraform && terraform plan

apply:
	@echo "Applying Terraform infrastructure..."
	@cd terraform && terraform apply -auto-approve

destroy:
	@echo "Destroying Terraform infrastructure..."
	@cd terraform && terraform destroy -auto-approve

configure: apply
	@echo "Configuring services with Ansible..."
	@chmod +x ansible/inventory/oci.py
	@ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/inventory/oci.py ansible/playbooks/site.yml

output:
	@echo "Displaying Terraform outputs..."
	@cd terraform && terraform output

clean:
	@echo "Cleaning up..."
	@rm -rf terraform/.terraform*
	@rm -f terraform/terraform.tfstate*

validate:
	@echo "Validating Terraform configuration..."
	@cd terraform && terraform validate

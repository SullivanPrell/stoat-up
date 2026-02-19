# Makefile for Stoat OCI Deployment

.PHONY: help init plan apply destroy ssh ansible-ping ansible-deploy clean cloudflare-setup

# Load environment variables from .env file if it exists
-include .env
export

# Variables
TERRAFORM_DIR := terraform
ANSIBLE_DIR := ansible
SSH_KEY ?= $(ANSIBLE_SSH_PRIVATE_KEY)
DOMAIN ?= $(STOAT_DOMAIN)
USE_CF_TUNNEL ?= $(USE_CLOUDFLARE_TUNNEL)

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Terraform targets
init: ## Initialize Terraform
	cd $(TERRAFORM_DIR) && terraform init

plan: ## Show Terraform plan
	cd $(TERRAFORM_DIR) && terraform plan

apply: ## Apply Terraform configuration
	cd $(TERRAFORM_DIR) && terraform apply

destroy: ## Destroy all infrastructure
	cd $(TERRAFORM_DIR) && terraform destroy

output: ## Show Terraform outputs
	cd $(TERRAFORM_DIR) && terraform output

# Ansible targets
ansible-ping: ## Test Ansible connectivity
	cd $(ANSIBLE_DIR) && ansible stoat -m ping --private-key $(SSH_KEY)

ansible-deploy: ## Deploy Stoat with Ansible
	cd $(ANSIBLE_DIR) && ansible-playbook playbook.yml \
		--private-key $(SSH_KEY) \
		-e "domain_name=$(DOMAIN)"

ansible-update: ## Update Stoat application
	cd $(ANSIBLE_DIR) && ansible-playbook playbook.yml \
		--private-key $(SSH_KEY) \
		-e "domain_name=$(DOMAIN)" \
		--tags update

# SSH and management
ssh: ## SSH into the instance
	@cd $(TERRAFORM_DIR) && ssh -i $(SSH_KEY) ubuntu@$$(terraform output -raw instance_public_ip)

logs: ## View Docker Compose logs
	@cd $(TERRAFORM_DIR) && ssh -i $(SSH_KEY) ubuntu@$$(terraform output -raw instance_public_ip) "cd /opt/stoat && docker compose logs -f"

status: ## Check service status
	@cd $(TERRAFORM_DIR) && ssh -i $(SSH_KEY) ubuntu@$$(terraform output -raw instance_public_ip) "cd /opt/stoat && docker compose ps"

restart: ## Restart Stoat services
	@cd $(TERRAFORM_DIR) && ssh -i $(SSH_KEY) ubuntu@$$(terraform output -raw instance_public_ip) "cd /opt/stoat && docker compose restart"

# Setup targets
setup: ## Setup configuration files from examples
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env - please edit it with your values"; \
		echo "Run 'make setup' again after configuring .env"; \
	else \
		echo ".env file exists - configuration loaded"; \
	fi

# Full deployment
deploy: init apply ansible-deploy ## Full deployment (Terraform + Ansible)
	@echo "Deployment complete!"
	@echo "Access your Stoat instance at: https://$(DOMAIN)"

# Cleanup
clean: ## Clean Terraform files
	rm -rf $(TERRAFORM_DIR)/.terraform
	rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl
	rm -f $(TERRAFORM_DIR)/terraform.tfstate*
	rm -f $(ANSIBLE_DIR)/inventory.ini

validate: ## Validate Terraform and Ansible configurations
	cd $(TERRAFORM_DIR) && terraform validate
	cd $(ANSIBLE_DIR) && ansible-playbook playbook.yml --syntax-check

check-env: ## Check if .env file exists and is configured
	@if [ ! -f .env ]; then \
		echo "ERROR: .env file not found!"; \
		echo "Run 'make setup' to create it from .env.example"; \
		exit 1; \
	fi
	@if grep -q "example.com" .env; then \
		echo "WARNING: .env file contains example values!"; \
		echo "Please edit .env with your actual configuration"; \
		exit 1; \
	fi
	@echo ".env file is configured"

# Cloudflare Tunnel targets
cloudflare-setup: ## Setup Cloudflare Tunnel (run this before deploying with Cloudflare)
	./setup-cloudflare-tunnel.sh

cloudflare-info: ## Show Cloudflare Tunnel information
	@if [ -z "$(CLOUDFLARE_TUNNEL_ID)" ]; then \
		echo "Cloudflare Tunnel not configured"; \
		echo "Run 'make cloudflare-setup' first"; \
	else \
		echo "Tunnel ID: $(CLOUDFLARE_TUNNEL_ID)"; \
		echo "Tunnel Name: $(CLOUDFLARE_TUNNEL_NAME)"; \
		echo "Domain: $(STOAT_DOMAIN)"; \
		cloudflared tunnel info $(CLOUDFLARE_TUNNEL_ID) 2>/dev/null || true; \
	fi

cloudflare-delete: ## Delete Cloudflare Tunnel
	@if [ -n "$(CLOUDFLARE_TUNNEL_ID)" ]; then \
		cloudflared tunnel delete $(CLOUDFLARE_TUNNEL_ID); \
		echo "Tunnel deleted. Please update .env file."; \
	else \
		echo "No tunnel configured in .env"; \
	fi

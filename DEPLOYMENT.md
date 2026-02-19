# Deploying Stoat to Oracle Cloud Infrastructure (OCI) Free Tier

This guide provides step-by-step instructions for deploying Stoat to OCI Free Tier using Terraform, Docker Compose, and Ansible.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
  - [1. OCI Account Setup](#1-oci-account-setup)
  - [2. Configure OCI CLI](#2-configure-oci-cli)
  - [3. Generate SSH Keys](#3-generate-ssh-keys)
  - [4. Configure Environment Variables](#4-configure-environment-variables)
  - [5. Deploy Infrastructure](#5-deploy-infrastructure)
  - [6. Configure DNS](#6-configure-dns)
  - [7. Deploy Application](#7-deploy-application)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)

## Prerequisites

Before you begin, ensure you have:

1. **Oracle Cloud Infrastructure (OCI) Account**: Sign up at https://www.oracle.com/cloud/free/
2. **Domain Name**: You'll need a domain name pointing to your server
3. **Local Tools**:
   - [Terraform](https://www.terraform.io/downloads) (>= 1.0)
   - [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (>= 2.9)
   - SSH client
   - Git
   - Make (optional, for convenience commands)

## Architecture Overview

This deployment uses:

- **Terraform**: Provisions OCI infrastructure (VCN, compute instance, security lists)
- **Docker Compose**: Orchestrates Stoat services (database, API, web, etc.)
- **Ansible**: Configures the server and deploys the application
- **Caddy**: Handles reverse proxy and automatic HTTPS
- **.env File**: Centralized configuration for all deployment variables

### OCI Free Tier Resources

This setup is designed to fit within OCI's Always Free tier:

- **Compute**: 1x VM.Standard.A1.Flex (ARM) with 2 OCPUs and 12GB RAM
  - OR 2x VM.Standard.E2.1.Micro (AMD) with 1 OCPU and 1GB RAM each
- **Block Storage**: 50GB boot volume (up to 200GB total available)
- **Networking**: 1 VCN with 1 subnet

## Quick Start

```bash
# Clone the repository
git clone https://github.com/SullivanPrell/stoat-up.git
cd stoat-up

# Setup configuration
make setup
# Edit .env with your values

# Validate configuration
./validate-env.sh

# Deploy infrastructure and application
make deploy
```

Or manually:

```bash
# Configure environment
cp .env.example .env
# Edit .env with your OCI credentials and settings

# Deploy infrastructure
source .env
cd terraform
terraform init
terraform plan
terraform apply

# Deploy application
cd ../ansible
ansible-playbook playbook.yml
```

## Detailed Setup

### 1. OCI Account Setup

1. Sign up for OCI at https://www.oracle.com/cloud/free/
2. Complete email verification
3. Set up your home region (cannot be changed later)
4. Complete identity verification (may take a few hours)

### 2. Configure OCI CLI

#### Get Your OCI Credentials

You need the following information from the OCI Console:

1. **Tenancy OCID**: 
   - Click on your profile → Tenancy: `<Your Tenancy Name>`
   - Copy the OCID

2. **User OCID**:
   - Click on your profile → User Settings
   - Copy the OCID

3. **Compartment OCID**:
   - For root compartment, use your tenancy OCID
   - Or navigate to Identity → Compartments

4. **Region**:
   - Your home region (e.g., `us-ashburn-1`, `us-phoenix-1`)

#### Generate API Key

1. Go to your user settings (Profile → User Settings)
2. Under "Resources", click "API Keys"
3. Click "Add API Key"
4. Choose "Generate API Key Pair"
5. Download both private and public keys
6. Save the private key to `~/.oci/oci_api_key.pem`
7. Set appropriate permissions:
   ```bash
   chmod 600 ~/.oci/oci_api_key.pem
   ```
8. Copy the fingerprint shown in the console

### 3. Generate SSH Keys

Generate an SSH key pair for server access:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/stoat_oci_rsa -C "stoat-oci"
chmod 600 ~/.ssh/stoat_oci_rsa
```

Copy your public key (you'll need this for the .env file):

```bash
cat ~/.ssh/stoat_oci_rsa.pub
```

### 4. Configure Environment Variables

All deployment configuration is managed through a single `.env` file.

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your values:
   ```bash
   # Use your preferred editor
   nano .env
   # or
   vim .env
   ```

3. Fill in all required values:

   ```bash
   # OCI Credentials (from step 2)
   TF_VAR_region=us-ashburn-1
   TF_VAR_tenancy_ocid=ocid1.tenancy.oc1..aaaaa...
   TF_VAR_user_ocid=ocid1.user.oc1..aaaaa...
   TF_VAR_fingerprint=aa:bb:cc:...
   TF_VAR_private_key_path=~/.oci/oci_api_key.pem
   TF_VAR_compartment_ocid=ocid1.compartment.oc1..aaaaa...
   
   # SSH Configuration (from step 3)
   TF_VAR_ssh_public_key=ssh-rsa AAAAB3NzaC1yc2E... stoat-oci
   ANSIBLE_SSH_PRIVATE_KEY=~/.ssh/stoat_oci_rsa
   
   # Stoat Configuration
   TF_VAR_domain_name=stoat.example.com
   STOAT_DOMAIN=stoat.example.com
   
   # Instance Configuration (adjust as needed)
   TF_VAR_instance_shape=VM.Standard.A1.Flex
   TF_VAR_instance_ocpus=2
   TF_VAR_instance_memory_in_gbs=12
   ```

4. Validate your configuration:
   ```bash
   ./validate-env.sh
   ```

   This script will:
   - Check all required variables are set
   - Verify SSH keys exist
   - Warn about example values
   - Check file permissions

### 5. Deploy Infrastructure

With your `.env` file configured:

1. Load environment variables:
   ```bash
   source .env
   ```

   Or if using Make (recommended):
   ```bash
   make init     # Initialize Terraform
   make plan     # Preview changes
   make apply    # Create infrastructure
   ```

   Manual Terraform commands:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

2. Note the output values:
   ```
   instance_public_ip = "xxx.xxx.xxx.xxx"
   ssh_command = "ssh ubuntu@xxx.xxx.xxx.xxx"
   ```

### 6. Configure DNS

Point your domain to the instance IP address:

1. Log in to your DNS provider (e.g., Cloudflare, Route53)
2. Create an A record:
   - **Name**: `@` (for root domain) or `stoat` (for subdomain)
   - **Type**: A
   - **Value**: The public IP from Terraform output
   - **TTL**: 300 (5 minutes) for testing, increase later

3. If you have IPv6, also create an AAAA record if OCI provides one

4. Verify DNS propagation:
   ```bash
   dig your.domain.com
   nslookup your.domain.com
   ```

### 7. Deploy Application

With infrastructure ready and DNS configured:

1. Ensure `.env` is loaded:
   ```bash
   source .env
   ```

2. Deploy with Ansible using Make:
   ```bash
   make ansible-deploy
   ```

   Or manually:
   ```bash
   cd ansible
   ansible-playbook playbook.yml
   ```

   The playbook will:
   - Update the system
   - Configure firewall
   - Install Docker
   - Clone and deploy Stoat
   - Configure SSL with Caddy

3. Wait for deployment (5-10 minutes)

4. Access your Stoat instance at `https://your.domain.com`

## Management

### Using Make Commands

The easiest way to manage your deployment is using the Makefile:

```bash
# View all available commands
make help

# SSH into the instance
make ssh

# View service logs
make logs

# Check service status
make status

# Restart services
make restart

# Update Stoat
make ansible-update
```

### Check Service Status

SSH into your instance:
```bash
source .env
make ssh
# or manually:
ssh -i ~/.ssh/stoat_oci_rsa ubuntu@<instance-ip>
```

Check Docker services:
```bash
cd /opt/stoat
docker compose ps
docker compose logs -f
```

### Update Stoat

```bash
cd /opt/stoat
git pull
docker compose pull
docker compose up -d
```

### Restart Services

```bash
cd /opt/stoat
docker compose restart
```

### View Logs

```bash
cd /opt/stoat
docker compose logs -f          # All services
docker compose logs -f api      # Specific service
```

### Backup Data

```bash
# Backup database
docker compose exec database mongodump --out /backup

# Backup MinIO data
sudo tar -czf stoat-backup-$(date +%Y%m%d).tar.gz /opt/stoat/data/
```

### Destroy Infrastructure

To remove all OCI resources:
```bash
cd terraform
terraform destroy
```

## Troubleshooting

### Instance Not Accessible

1. **Check security list**: Ensure ports 22, 80, 443 are open
2. **Check firewall**: 
   ```bash
   sudo ufw status
   ```
3. **Verify instance is running** in OCI Console

### Services Not Starting

1. **Check Docker**:
   ```bash
   sudo systemctl status docker
   ```

2. **Check logs**:
   ```bash
   cd /opt/stoat
   docker compose logs
   ```

3. **Check disk space**:
   ```bash
   df -h
   ```

### SSL Certificate Issues

Caddy automatically provisions SSL certificates. If there are issues:

1. **Ensure DNS is pointing to the correct IP**
2. **Check Caddy logs**:
   ```bash
   docker compose logs caddy
   ```
3. **Verify domain ownership**: Caddy uses ACME (Let's Encrypt)

### Out of Memory

If using VM.Standard.E2.1.Micro (1GB RAM):

1. **Add swap space**:
   ```bash
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

2. **Consider upgrading to VM.Standard.A1.Flex** with more RAM

## Cost Optimization

### Staying Within Free Tier

- **Compute**: Use VM.Standard.A1.Flex with up to 4 OCPUs and 24GB RAM total
- **Storage**: Up to 200GB block storage total
- **Egress**: 10TB/month outbound data transfer
- **Always monitor usage** in OCI Console → Billing → Cost Analysis

### Resource Monitoring

```bash
# CPU and Memory usage
docker stats

# Disk usage
df -h
du -sh /opt/stoat/data/*
```

### Cleanup Old Data

```bash
# Clean Docker
docker system prune -a

# Clean old logs
docker compose logs --tail 1000 > /tmp/logs.txt
# Then manually review and truncate if needed
```

## Security Recommendations

1. **Enable Fail2Ban** (done by Ansible)
2. **Use strong passwords** for database if exposed
3. **Regular updates**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
4. **Monitor logs** for suspicious activity
5. **Use Cloudflare** for additional DDoS protection
6. **Enable OCI Cloud Guard** for threat detection

## Next Steps

- Configure email verification (SMTP settings in `Revolt.toml`)
- Set up backups (automated with cron)
- Configure captcha for registration
- Set up monitoring (Prometheus/Grafana)
- Enable invite-only mode if desired

## Support

- **Stoat Repository**: https://github.com/SullivanPrell/stoat-up
- **Original Revolt Self-Hosted**: https://github.com/revoltchat/self-hosted
- **OCI Documentation**: https://docs.oracle.com/iaas/
- **Terraform OCI Provider**: https://registry.terraform.io/providers/oracle/oci/

## License

This deployment configuration is provided as-is. Stoat/Revolt has its own licensing terms - please consult the original repository.

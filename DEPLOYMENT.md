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
  - [4. Configure Terraform](#4-configure-terraform)
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

## Architecture Overview

This deployment uses:

- **Terraform**: Provisions OCI infrastructure (VCN, compute instance, security lists)
- **Docker Compose**: Orchestrates Stoat services (database, API, web, etc.)
- **Ansible**: Configures the server and deploys the application
- **Caddy**: Handles reverse proxy and automatic HTTPS

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

# Configure Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your OCI credentials

# Deploy infrastructure
terraform init
terraform plan
terraform apply

# Deploy application with Ansible
cd ../ansible
ansible-playbook playbook.yml -e "domain_name=your.domain.com"
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

### 4. Configure Terraform

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your values:
   ```hcl
   # OCI Configuration
   region           = "us-ashburn-1"  # Your OCI region
   tenancy_ocid     = "ocid1.tenancy.oc1..aaaaa..."
   user_ocid        = "ocid1.user.oc1..aaaaa..."
   fingerprint      = "aa:bb:cc:dd:..."
   private_key_path = "~/.oci/oci_api_key.pem"
   compartment_ocid = "ocid1.compartment.oc1..aaaaa..."
   
   # SSH Configuration
   ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... stoat-oci"
   
   # Stoat Configuration
   domain_name = "stoat.example.com"
   
   # Instance Configuration (Free Tier)
   instance_shape          = "VM.Standard.A1.Flex"
   instance_ocpus          = 2
   instance_memory_in_gbs  = 12
   boot_volume_size_in_gbs = "50"
   ```

   **Note**: To use your SSH public key, run:
   ```bash
   cat ~/.ssh/stoat_oci_rsa.pub
   ```

### 5. Deploy Infrastructure

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the deployment plan:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```
   Type `yes` when prompted.

4. Note the output values:
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

1. Navigate to the ansible directory:
   ```bash
   cd ../ansible
   ```

2. The inventory file should have been auto-generated by Terraform. If not, create it:
   ```bash
   cp inventory.ini.example inventory.ini
   # Edit with your instance IP
   ```

3. Test Ansible connectivity:
   ```bash
   ansible stoat -m ping -i inventory.ini --private-key ~/.ssh/stoat_oci_rsa
   ```

4. Run the playbook:
   ```bash
   ansible-playbook playbook.yml \
     -i inventory.ini \
     --private-key ~/.ssh/stoat_oci_rsa \
     -e "domain_name=your.domain.com"
   ```

5. Wait for deployment to complete (5-10 minutes)

6. Access your Stoat instance at `https://your.domain.com`

## Management

### Check Service Status

SSH into your instance:
```bash
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

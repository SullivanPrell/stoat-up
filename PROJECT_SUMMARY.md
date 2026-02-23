# Stoat-Up OCI Deployment - Project Summary

## Overview

This repository contains a complete, production-ready deployment solution for Stoat (Revolt Chat) on Oracle Cloud Infrastructure's Free Tier. The deployment uses modern infrastructure-as-code practices with Terraform, Ansible, Docker Compose, and centralized environment variable configuration.

## What Was Added

### Infrastructure as Code (Terraform)

**Location:** `terraform/`

- Complete OCI infrastructure provisioning
- VCN, subnet, internet gateway, route tables
- Security lists (SSH, HTTP, HTTPS)
- Compute instance (ARM or x86 free tier)
- Auto-generates Ansible inventory
- Cloud-init for basic server setup

**Key Files:**
- `main.tf` - Main infrastructure configuration
- `variables.tf` - Variable definitions
- `outputs.tf` - Output values (IP, SSH command, etc.)
- `cloud-init.yaml` - Initial server configuration
- `inventory.tpl` - Ansible inventory template

### Configuration Management (Ansible)

**Location:** `ansible/`

- Automated server configuration and hardening
- Docker and Docker Compose installation
- Application deployment and startup
- Security setup (UFW firewall, fail2ban)
- Reads configuration from environment variables

**Key Files:**
- `playbook.yml` - Main deployment playbook
- `ansible.cfg` - Ansible configuration with env var support
- `inventory.ini.example` - Example inventory file

### Centralized Configuration

**Location:** Root directory

- **`.env.example`** - Complete template with all required variables
  - OCI credentials (tenancy, user, API keys)
  - SSH keys configuration
  - Instance specifications
  - Domain configuration
  - Ansible settings

- **`validate-env.sh`** - Configuration validation script
  - Checks all required variables
  - Validates file paths and permissions
  - Warns about example values
  - Color-coded output

### Automation & Convenience

**Location:** Root directory

- **`Makefile`** - One-command deployment and management
  - `make setup` - Create .env from template
  - `make deploy` - Full deployment
  - `make ssh` - Connect to server
  - `make logs` - View application logs
  - `make validate` - Validate configurations
  - And many more...

### Documentation

**Location:** Root directory and subdirectories

1. **`DEPLOYMENT.md`** - Complete deployment guide
   - Prerequisites and setup
   - Step-by-step instructions
   - OCI account configuration
   - DNS setup
   - Troubleshooting

2. **`QUICK_REFERENCE.md`** - Quick command reference
   - Common tasks
   - Environment variables
   - Make commands
   - On-server management
   - Backup procedures

3. **`README.md`** - Updated with OCI deployment section
   - Quick start guide
   - Links to detailed docs
   - Feature highlights

4. **`terraform/README.md`** - Terraform-specific docs
   - Configuration details
   - OCI free tier options
   - Customization guide

5. **`ansible/README.md`** - Ansible-specific docs
   - Playbook details
   - Configuration options
   - Usage examples

### CI/CD

**Location:** `.github/workflows/`

- **`validate-deployment.yml`** - GitHub Actions workflow
  - Validates Terraform syntax
  - Validates Ansible syntax
  - Checks .env.example completeness
  - Verifies documentation exists

### Additional Files

- **`compose.override.yml.example`** - Docker Compose customization template
- **`.gitignore`** - Updated to exclude sensitive files (.env, Terraform state, etc.)

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Developer Machine                   │
│                                                      │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐    │
│  │   .env   │→ │ Terraform │→ │   Ansible    │    │
│  │  Config  │  │           │  │              │    │
│  └──────────┘  └─────┬─────┘  └──────┬───────┘    │
│                      │                │             │
└──────────────────────┼────────────────┼─────────────┘
                       │                │
                       ▼                ▼
              ┌─────────────────────────────┐
              │   Oracle Cloud (OCI)        │
              │                             │
              │  ┌──────────────────────┐  │
              │  │  VCN & Security      │  │
              │  └──────────────────────┘  │
              │            │                │
              │            ▼                │
              │  ┌──────────────────────┐  │
              │  │  Compute Instance    │  │
              │  │  ┌────────────────┐  │  │
              │  │  │ Docker Compose │  │  │
              │  │  │  ┌──────────┐  │  │  │
              │  │  │  │  Caddy   │  │  │  │
              │  │  │  │  (HTTPS) │  │  │  │
              │  │  │  └────┬─────┘  │  │  │
              │  │  │       │        │  │  │
              │  │  │  ┌────▼─────┐  │  │  │
              │  │  │  │  Stoat   │  │  │  │
              │  │  │  │ Services │  │  │  │
              │  │  │  └──────────┘  │  │  │
              │  │  └────────────────┘  │  │
              │  └──────────────────────┘  │
              └─────────────────────────────┘
```

## Deployment Flow

1. **Setup Configuration**
   ```bash
   make setup              # Creates .env from template
   # Edit .env with actual values
   ./validate-env.sh       # Validate configuration
   ```

2. **Deploy Infrastructure** (Terraform)
   ```bash
   make init               # Initialize Terraform
   make apply              # Create OCI resources
   ```
   - Creates VCN, subnet, security lists
   - Provisions compute instance
   - Configures networking
   - Generates Ansible inventory

3. **Configure Server** (Ansible)
   ```bash
   make ansible-deploy     # Run Ansible playbook
   ```
   - Updates system packages
   - Hardens security (firewall, fail2ban)
   - Installs Docker
   - Deploys Stoat
   - Starts all services

4. **Access Application**
   - Navigate to `https://your-domain.com`
   - Caddy automatically provisions SSL certificate

## Key Features

### ✅ Single Configuration File
- All settings in `.env`
- No scattered config files
- Environment variable based
- Easy to backup and restore

### ✅ One-Command Deployment
- `make deploy` - Full deployment
- `make ssh` - Connect to server
- `make logs` - View logs
- `make destroy` - Clean up

### ✅ Production Ready
- Security hardening included
- Firewall configured
- Automatic SSL/HTTPS
- fail2ban protection

### ✅ Free Tier Optimized
- ARM instance (2 OCPUs, 12GB RAM)
- OR x86 micro (1 OCPU, 1GB RAM)
- Fits within OCI Always Free tier
- Cost: $0/month

### ✅ Well Documented
- Complete deployment guide
- Quick reference
- Troubleshooting tips
- Examples included

### ✅ Automated Validation
- Configuration validation script
- GitHub Actions CI/CD
- Terraform validation
- Ansible syntax checks

## File Structure

```
stoat-up/
├── .env.example                  # Configuration template
├── .gitignore                    # Excludes sensitive files
├── validate-env.sh               # Configuration validator
├── Makefile                      # Convenience commands
│
├── DEPLOYMENT.md                 # Complete deployment guide
├── QUICK_REFERENCE.md            # Quick command reference
├── README.md                     # Main readme
│
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                   # Main configuration
│   ├── variables.tf              # Variable definitions
│   ├── outputs.tf                # Output values
│   ├── cloud-init.yaml           # Server initialization
│   ├── inventory.tpl             # Ansible inventory template
│   ├── terraform.tfvars.example  # Legacy config (for reference)
│   └── README.md                 # Terraform documentation
│
├── ansible/                      # Configuration Management
│   ├── playbook.yml              # Main deployment playbook
│   ├── ansible.cfg               # Ansible configuration
│   ├── inventory.ini.example     # Example inventory
│   ├── vars.yml.example          # Legacy vars (for reference)
│   └── README.md                 # Ansible documentation
│
├── .github/
│   └── workflows/
│       └── validate-deployment.yml  # CI/CD validation
│
└── [Original Stoat Files]
    ├── compose.yml               # Docker Compose config
    ├── Caddyfile                 # Reverse proxy config
    ├── generate_config.sh        # Config generator
    └── migrations/               # Database migrations
```

## Environment Variables

The `.env` file contains:

**OCI Credentials:**
- `TF_VAR_region` - OCI region
- `TF_VAR_tenancy_ocid` - Tenancy OCID
- `TF_VAR_user_ocid` - User OCID
- `TF_VAR_fingerprint` - API key fingerprint
- `TF_VAR_private_key_path` - Path to OCI API key
- `TF_VAR_compartment_ocid` - Compartment OCID

**Instance Configuration:**
- `TF_VAR_instance_shape` - VM shape (ARM or x86)
- `TF_VAR_instance_ocpus` - Number of OCPUs
- `TF_VAR_instance_memory_in_gbs` - Memory size
- `TF_VAR_boot_volume_size_in_gbs` - Disk size

**SSH Configuration:**
- `TF_VAR_ssh_public_key` - SSH public key
- `ANSIBLE_SSH_PRIVATE_KEY` - SSH private key path

**Application Configuration:**
- `TF_VAR_domain_name` - Domain for Stoat
- `STOAT_DOMAIN` - Same as domain_name
- `STOAT_DIR` - Installation directory

## Resource Requirements

### Minimum (x86 Micro)
- Instance: VM.Standard.E2.1.Micro
- vCPUs: 1
- Memory: 1 GB
- Storage: 50 GB

### Recommended (ARM Flex)
- Instance: VM.Standard.A1.Flex
- vCPUs: 2-4
- Memory: 12-24 GB
- Storage: 50-100 GB

Both options are free tier eligible!

## Security Features

- ✅ UFW firewall configured
- ✅ fail2ban installed and enabled
- ✅ SSH password authentication disabled
- ✅ SSH key-only access
- ✅ Security lists restrict access
- ✅ Automatic HTTPS with Let's Encrypt
- ✅ Regular security updates

## Maintenance

### Update Stoat
```bash
make ansible-update
# Or on server:
cd /opt/stoat
git pull
docker compose pull
docker compose up -d
```

### View Logs
```bash
make logs
# Or on server:
cd /opt/stoat
docker compose logs -f
```

### Backup Data
```bash
# Database
docker compose exec database mongodump --archive > backup.archive

# Full backup
sudo tar -czf stoat-backup.tar.gz /opt/stoat/data/
```

### Destroy Everything
```bash
make destroy
```

## Testing

To test without actual deployment:

```bash
# Validate Terraform
make validate

# Check .env configuration
./validate-env.sh

# Terraform dry run
make plan

# Ansible dry run
cd ansible
ansible-playbook playbook.yml --check
```

## Troubleshooting

See [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting) for complete troubleshooting guide.

Quick checks:
- `.env` file exists and configured: `./validate-env.sh`
- SSH keys correct permissions: `chmod 600 ~/.ssh/stoat_oci_rsa`
- DNS propagated: `dig your-domain.com`
- Services running: `make status`

## Contributing

Improvements welcome! Areas for contribution:
- Additional cloud providers (AWS, Azure, GCP)
- Monitoring setup (Prometheus, Grafana)
- Backup automation
- Multi-region deployment
- High availability setup

## License

This deployment configuration is provided as-is. Stoat/Revolt has its own licensing - see the original repository.

## Credits

- **Stoat/Revolt**: https://github.com/revoltchat/self-hosted
- **OCI Free Tier**: https://www.oracle.com/cloud/free/
- **Terraform**: https://www.terraform.io/
- **Ansible**: https://www.ansible.com/

## Support

- **Deployment Issues**: Open an issue in this repository
- **Stoat Application**: See https://github.com/revoltchat/self-hosted
- **OCI Issues**: See https://docs.oracle.com/iaas/

---

**Ready to deploy? Start with: `make setup`**

# Quick Reference Guide

This is a quick reference for common tasks when deploying and managing Stoat on OCI.

## Initial Setup

### Standard Setup (Caddy)

```bash
# 1. Clone repository
git clone https://github.com/SullivanPrell/stoat-up.git
cd stoat-up

# 2. Setup configuration
make setup  # Creates .env from .env.example

# 3. Edit .env with your values
nano .env   # or vim .env

# 4. Validate configuration
./validate-env.sh

# 5. Deploy everything
make deploy
```

### Cloudflare Tunnel Setup (No Port Exposure)

```bash
# 1. Clone repository
git clone https://github.com/SullivanPrell/stoat-up.git
cd stoat-up

# 2. Setup configuration
make setup

# 3. Edit .env with OCI AND Cloudflare credentials
nano .env
# Add: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_ZONE_ID

# 4. Setup Cloudflare Tunnel
make cloudflare-setup

# 5. Enable Cloudflare in .env
# Set: USE_CLOUDFLARE_TUNNEL=true

# 6. Deploy everything
make deploy
```

## Environment Variables

All configuration is in `.env` file. Key variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `TF_VAR_region` | OCI region | `us-ashburn-1` |
| `TF_VAR_tenancy_ocid` | OCI tenancy ID | `ocid1.tenancy.oc1..aaaa...` |
| `TF_VAR_domain_name` | Your domain | `stoat.example.com` |
| `STOAT_DOMAIN` | Same as domain_name | `stoat.example.com` |
| `TF_VAR_ssh_public_key` | SSH public key | `ssh-rsa AAAAB3...` |
| `ANSIBLE_SSH_PRIVATE_KEY` | SSH private key path | `~/.ssh/stoat_oci_rsa` |
| **Cloudflare (Optional)** | | |
| `USE_CLOUDFLARE_TUNNEL` | Enable Cloudflare Tunnel | `true` or `false` |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token | `your_token_here` |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account ID | `abc123...` |
| `CLOUDFLARE_ZONE_ID` | Cloudflare zone ID | `def456...` |
| `CLOUDFLARE_TUNNEL_NAME` | Tunnel name | `stoat-tunnel` |

See `.env.example` for complete list.

## Make Commands

```bash
make help              # Show all commands
make setup             # Create .env from example
make check-env         # Validate .env configuration
make validate          # Validate Terraform and Ansible

# Deployment
make init              # Initialize Terraform
make plan              # Show Terraform plan
make apply             # Deploy infrastructure
make ansible-deploy    # Deploy application
make deploy            # Full deployment (apply + ansible)

# Cloudflare Tunnel
make cloudflare-setup  # Setup Cloudflare Tunnel
make cloudflare-info   # Show tunnel information
make cloudflare-delete # Delete Cloudflare Tunnel

# Management
make ssh               # SSH into instance
make logs              # View Docker logs
make status            # Check service status
make restart           # Restart all services

# Cleanup
make destroy           # Destroy all infrastructure
make clean             # Clean local Terraform files
```

## Manual Commands

### Terraform

```bash
# Load environment
source .env

# Deploy
cd terraform
terraform init
terraform plan
terraform apply

# Show outputs
terraform output

# Destroy
terraform destroy
```

### Ansible

```bash
# Load environment
source .env

# Deploy
cd ansible
ansible-playbook playbook.yml

# Test connectivity
ansible stoat -m ping

# Run specific tasks
ansible-playbook playbook.yml --tags setup
```

### SSH Access

```bash
# Using Make
make ssh

# Manual
source .env
ssh -i $ANSIBLE_SSH_PRIVATE_KEY ubuntu@<instance-ip>
```

## Cloudflare Tunnel Commands

### Setup and Management

```bash
# One-time setup
make cloudflare-setup

# View tunnel info
make cloudflare-info
cloudflared tunnel info stoat-tunnel

# List all tunnels
cloudflared tunnel list

# Delete tunnel
make cloudflare-delete
cloudflared tunnel delete stoat-tunnel

# Test tunnel configuration
cloudflared tunnel ingress validate
```

### Docker Compose with Cloudflare

```bash
# Start with Cloudflare Tunnel
docker compose -f compose.yml -f compose.cloudflare.yml up -d

# View cloudflared logs
docker compose logs -f cloudflared

# Restart tunnel
docker compose restart cloudflared

# Stop tunnel
docker compose stop cloudflared
```

## On Server

Once connected to the server:

```bash
# Navigate to Stoat directory
cd /opt/stoat

# View all services
docker compose ps

# View logs
docker compose logs -f           # All services
docker compose logs -f api       # Specific service
docker compose logs --tail 100   # Last 100 lines

# Restart services
docker compose restart           # All services
docker compose restart api       # Specific service

# Stop/Start
docker compose stop
docker compose start
docker compose up -d

# Update Stoat
git pull
docker compose pull
docker compose up -d

# Check disk space
df -h
du -sh data/*

# View configuration
cat Revolt.toml
cat .env.web
```

## DNS Configuration

### Traditional Setup (Caddy)

Point your domain to the instance IP:

```
Type: A
Name: @ (or subdomain)
Value: <instance-public-ip>
TTL: 300
```

Verify:
```bash
dig your.domain.com
nslookup your.domain.com
```

### Cloudflare Tunnel Setup

**Automatic** - The tunnel script handles DNS:
```bash
# DNS is created automatically by setup-cloudflare-tunnel.sh
# Creates CNAME: your-domain.com → tunnel-id.cfargotunnel.com
```

**Manual** (if needed):
```bash
cloudflared tunnel route dns stoat-tunnel your-domain.com
```

## Firewall Rules

### With Caddy (Traditional)

The following ports are open:

- **22**: SSH
- **80**: HTTP (redirects to HTTPS)
- **443**: HTTPS

Check firewall:
```bash
sudo ufw status
```

### With Cloudflare Tunnel

**Only SSH is needed** - No HTTP/HTTPS ports exposed:

- **22**: SSH

```bash
sudo ufw allow 22/tcp
sudo ufw default deny incoming
sudo ufw enable
```

The tunnel creates an **outbound-only** connection to Cloudflare.

## Backup

### Database Backup

```bash
# On server
cd /opt/stoat
docker compose exec database mongodump --archive > backup.archive

# Or with timestamp
docker compose exec database mongodump --archive > backup-$(date +%Y%m%d).archive
```

### Full Backup

```bash
# On server
sudo tar -czf stoat-backup-$(date +%Y%m%d).tar.gz /opt/stoat/data/
```

### Download Backup

```bash
# From local machine
source .env
scp -i $ANSIBLE_SSH_PRIVATE_KEY ubuntu@<instance-ip>:/opt/stoat/backup.archive .
```

## Troubleshooting

### Services not starting

```bash
# Check Docker
sudo systemctl status docker

# Check logs
cd /opt/stoat
docker compose logs

# Restart services
docker compose restart
```

### Cloudflare Tunnel not connecting

```bash
# Check cloudflared logs
docker compose logs cloudflared

# Verify tunnel exists
cloudflared tunnel list

# Test tunnel configuration
cloudflared tunnel ingress validate

# Restart tunnel
docker compose restart cloudflared
```

### Out of disk space

```bash
# Check space
df -h

# Clean Docker
docker system prune -a

# Check data directories
du -sh /opt/stoat/data/*
```

### SSL issues

```bash
# Check Caddy logs
docker compose logs caddy

# Verify DNS
dig your.domain.com

# Restart Caddy
docker compose restart caddy
```

### Cannot SSH

```bash
# Check instance is running in OCI Console

# Check security list allows port 22

# Check firewall
sudo ufw status

# Check SSH key permissions
chmod 600 ~/.ssh/stoat_oci_rsa
```

## Useful Paths

- **Configuration**: `/opt/stoat/Revolt.toml`, `/opt/stoat/.env.web`
- **Data**: `/opt/stoat/data/`
- **Database**: `/opt/stoat/data/db/`
- **Files**: `/opt/stoat/data/minio/`
- **Logs**: `docker compose logs`

## Getting Help

- **Deployment docs**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Cloudflare Tunnel**: [CLOUDFLARE_TUNNEL.md](CLOUDFLARE_TUNNEL.md)
- **Terraform README**: [terraform/README.md](terraform/README.md)
- **Ansible README**: [ansible/README.md](ansible/README.md)
- **Original Stoat**: https://github.com/revoltchat/self-hosted

## Deployment Options Comparison

| Feature | Caddy (Traditional) | Cloudflare Tunnel |
|---------|---------------------|-------------------|
| Port exposure | 80, 443 | None |
| SSL certificates | Let's Encrypt | Cloudflare |
| DNS setup | Manual | Automatic |
| DDoS protection | None | Built-in |
| Setup complexity | Simple | Moderate |
| Server IP | Public | Hidden |
| Firewall rules | Allow 80/443 | Only SSH |

## Security Checklist

- [ ] `.env` file is not committed to git
- [ ] SSH key has 600 permissions
- [ ] Changed default passwords (if any)
- [ ] Firewall is enabled
- [ ] fail2ban is running
- [ ] Regular backups configured
- [ ] DNS uses Cloudflare or similar for DDoS protection
- [ ] OCI Cloud Guard enabled
- [ ] For Cloudflare: Tunnel token is secure
- [ ] For Cloudflare: API token has minimum permissions

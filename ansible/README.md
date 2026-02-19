# Ansible Configuration for Stoat Deployment

This directory contains Ansible playbooks and configuration for deploying and configuring Stoat on OCI instances.

## Files

- `playbook.yml` - Main deployment playbook
- `ansible.cfg` - Ansible configuration
- `inventory.ini.example` - Example inventory file
- `vars.yml.example` - Example variables file

## What the Playbook Does

The Ansible playbook automates the following tasks:

1. **System Updates**: Updates all packages and applies security patches
2. **Security Hardening**:
   - Configures UFW firewall (SSH, HTTP, HTTPS)
   - Installs and enables fail2ban
   - Ensures SSH password authentication is disabled
3. **Docker Installation**: Installs Docker CE and Docker Compose
4. **Application Deployment**:
   - Clones the Stoat repository
   - Generates configuration with your domain
   - Creates necessary directories
   - Starts all services with Docker Compose

## Prerequisites

1. **Instance Ready**: OCI instance provisioned (via Terraform or manually)
2. **SSH Access**: SSH key with access to the instance
3. **Ansible Installed**: Ansible >= 2.9
   ```bash
   # Ubuntu/Debian
   sudo apt install ansible
   
   # macOS
   brew install ansible
   
   # pip
   pip install ansible
   ```
4. **Domain Configured**: DNS A record pointing to instance IP

## Quick Start

If you used Terraform, the inventory file is auto-generated. Otherwise:

1. Create inventory file:
   ```bash
   cp inventory.ini.example inventory.ini
   # Edit with your instance IP
   ```

2. Test connectivity:
   ```bash
   ansible stoat -m ping --private-key ~/.ssh/stoat_oci_rsa
   ```

3. Run the playbook:
   ```bash
   ansible-playbook playbook.yml \
     --private-key ~/.ssh/stoat_oci_rsa \
     -e "domain_name=your.domain.com"
   ```

## Configuration Options

### Inventory File

The `inventory.ini` file specifies the target server(s):

```ini
[stoat]
xxx.xxx.xxx.xxx ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### Variables

You can pass variables in several ways:

1. **Command line** (recommended):
   ```bash
   ansible-playbook playbook.yml -e "domain_name=stoat.example.com"
   ```

2. **Variables file**:
   ```bash
   cp vars.yml.example vars.yml
   # Edit vars.yml
   ansible-playbook playbook.yml -e "@vars.yml"
   ```

3. **In playbook** (edit playbook.yml):
   ```yaml
   vars:
     domain_name: "stoat.example.com"
   ```

### Available Variables

- `domain_name` (required): Your domain name for Stoat
- `stoat_dir` (default: `/opt/stoat`): Installation directory

## Running the Playbook

### Basic Usage

```bash
ansible-playbook playbook.yml -e "domain_name=your.domain.com"
```

### With Custom SSH Key

```bash
ansible-playbook playbook.yml \
  --private-key ~/.ssh/stoat_oci_rsa \
  -e "domain_name=your.domain.com"
```

### With Custom Inventory

```bash
ansible-playbook playbook.yml \
  -i /path/to/inventory.ini \
  -e "domain_name=your.domain.com"
```

### Dry Run (Check Mode)

```bash
ansible-playbook playbook.yml \
  --check \
  -e "domain_name=your.domain.com"
```

### Verbose Output

```bash
ansible-playbook playbook.yml \
  -vvv \
  -e "domain_name=your.domain.com"
```

## Post-Deployment

After the playbook completes:

1. **Access Stoat**: Navigate to `https://your.domain.com`
2. **Check logs**: 
   ```bash
   ssh ubuntu@<instance-ip>
   cd /opt/stoat
   docker compose logs -f
   ```
3. **Verify services**:
   ```bash
   docker compose ps
   ```

## Maintenance Playbooks

### Update Stoat

Create `update.yml`:

```yaml
---
- name: Update Stoat
  hosts: stoat
  become: yes
  tasks:
    - name: Pull latest code
      git:
        repo: https://github.com/SullivanPrell/stoat-up.git
        dest: /opt/stoat
        version: main
        force: yes

    - name: Pull latest images
      command: docker compose pull
      args:
        chdir: /opt/stoat

    - name: Restart services
      command: docker compose up -d
      args:
        chdir: /opt/stoat
```

Run with:
```bash
ansible-playbook update.yml
```

### Backup Data

Create `backup.yml`:

```yaml
---
- name: Backup Stoat Data
  hosts: stoat
  become: yes
  vars:
    backup_dest: "/backup/stoat-{{ ansible_date_time.iso8601_basic_short }}"
  tasks:
    - name: Create backup directory
      file:
        path: "{{ backup_dest }}"
        state: directory

    - name: Backup database
      command: docker compose exec -T database mongodump --archive
      args:
        chdir: /opt/stoat
      register: mongodump_output

    - name: Save database backup
      copy:
        content: "{{ mongodump_output.stdout }}"
        dest: "{{ backup_dest }}/mongodb.archive"

    - name: Backup configuration
      copy:
        src: "/opt/stoat/{{ item }}"
        dest: "{{ backup_dest }}/"
        remote_src: yes
      loop:
        - Revolt.toml
        - .env.web
```

## Troubleshooting

### Connection Issues

```bash
# Test SSH connectivity
ssh -i ~/.ssh/stoat_oci_rsa ubuntu@<instance-ip>

# Test Ansible connectivity
ansible stoat -m ping --private-key ~/.ssh/stoat_oci_rsa
```

### Permission Denied

Ensure your SSH key is correct and has proper permissions:
```bash
chmod 600 ~/.ssh/stoat_oci_rsa
```

### Playbook Fails on Docker Installation

ARM instances (VM.Standard.A1.Flex) use aarch64 architecture. The playbook automatically handles this.

If issues persist:
```bash
# SSH into the instance
ssh -i ~/.ssh/stoat_oci_rsa ubuntu@<instance-ip>

# Manually install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu
```

### Services Don't Start

1. Check Docker:
   ```bash
   sudo systemctl status docker
   ```

2. Check logs:
   ```bash
   cd /opt/stoat
   docker compose logs
   ```

3. Verify configuration:
   ```bash
   cat /opt/stoat/Revolt.toml
   cat /opt/stoat/.env.web
   ```

## Customization

### Different Installation Directory

```bash
ansible-playbook playbook.yml \
  -e "domain_name=your.domain.com" \
  -e "stoat_dir=/home/ubuntu/stoat"
```

### Skip Certain Tasks

Use tags (need to add to playbook):

```yaml
tasks:
  - name: Task name
    ...
    tags: ['setup', 'security']
```

Then run:
```bash
ansible-playbook playbook.yml --skip-tags security
```

## Advanced Usage

### Multiple Servers

Add more hosts to inventory:

```ini
[stoat]
server1.example.com
server2.example.com

[stoat:vars]
ansible_user=ubuntu
```

### Use Ansible Vault for Secrets

```bash
# Create encrypted vars
ansible-vault create secrets.yml

# Run with vault
ansible-playbook playbook.yml --ask-vault-pass -e "@secrets.yml"
```

## Next Steps

See the main [DEPLOYMENT.md](../DEPLOYMENT.md) for:
- Complete deployment guide
- DNS configuration
- SSL setup
- Monitoring and maintenance
- Troubleshooting tips

## Support

For issues specific to:
- **Ansible**: Check the Ansible documentation
- **Stoat**: See the main repository
- **OCI**: Consult OCI documentation

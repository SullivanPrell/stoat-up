# Terraform Configuration for OCI

This directory contains Terraform configuration to provision infrastructure on Oracle Cloud Infrastructure (OCI) for deploying Stoat.

## Files

- `main.tf` - Main Terraform configuration (VCN, compute instance, security)
- `variables.tf` - Variable definitions
- `outputs.tf` - Output values (IP address, instance ID, etc.)
- `terraform.tfvars.example` - Example variables file (deprecated - use .env instead)
- `cloud-init.yaml` - Cloud-init configuration for instance
- `inventory.tpl` - Template for Ansible inventory file

## Quick Start

**Recommended: Use the .env file approach**

From the repository root:

```bash
# 1. Setup configuration
make setup
# Edit .env with your values

# 2. Validate
./validate-env.sh

# 3. Deploy
make init
make plan
make apply
```

**Alternative: Manual approach**

```bash
# 1. Load environment variables
source ../.env

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Apply the configuration
terraform apply
```

## Configuration

All configuration is done via environment variables using the `.env` file in the repository root.

Terraform reads variables prefixed with `TF_VAR_`. For example:
- `.env` contains: `TF_VAR_region=us-ashburn-1`
- Terraform uses: `var.region`

### Required Environment Variables

See `.env.example` for the complete list. Key variables:

- `TF_VAR_region` - OCI region
- `TF_VAR_tenancy_ocid` - Your tenancy OCID
- `TF_VAR_user_ocid` - Your user OCID
- `TF_VAR_fingerprint` - API key fingerprint
- `TF_VAR_private_key_path` - Path to OCI API private key
- `TF_VAR_compartment_ocid` - Compartment OCID
- `TF_VAR_ssh_public_key` - SSH public key for instance
- `TF_VAR_domain_name` - Domain for your Stoat instance

### Legacy Configuration (terraform.tfvars)

The `terraform.tfvars.example` file is provided for reference but is no longer the recommended approach. Use the `.env` file instead.

This configuration is optimized for OCI's Always Free tier:

### Option 1: ARM Instance (Recommended)
- **Shape**: VM.Standard.A1.Flex
- **OCPUs**: 2 (up to 4 total across all instances)
- **Memory**: 12GB (up to 24GB total across all instances)
- **Storage**: 50GB boot volume (up to 200GB total)

### Option 2: x86 Instance
- **Shape**: VM.Standard.E2.1.Micro
- **OCPUs**: 1
- **Memory**: 1GB
- **Storage**: 50GB boot volume

## Prerequisites

1. OCI account with free tier eligibility
2. OCI API key pair generated
3. SSH key pair for instance access
4. Terraform >= 1.0 installed

## Obtaining OCI Credentials

### Tenancy OCID
1. Log in to OCI Console
2. Click your profile → Tenancy
3. Copy the OCID

### User OCID
1. Click your profile → User Settings
2. Copy the OCID

### API Key
1. Go to User Settings → API Keys
2. Click "Add API Key"
3. Download the private key to `~/.oci/oci_api_key.pem`
4. Set permissions: `chmod 600 ~/.oci/oci_api_key.pem`
5. Copy the fingerprint

### Region
Your OCI home region (e.g., us-ashburn-1, us-phoenix-1, eu-frankfurt-1)

## Outputs

After applying, Terraform provides:

- `instance_public_ip` - Public IP address of the instance
- `instance_id` - OCID of the compute instance
- `ssh_command` - Command to SSH into the instance
- Auto-generated `../ansible/inventory.ini` for Ansible

## Customization

### Using a Different Instance Shape

Edit `terraform.tfvars`:

```hcl
# For x86 micro instance
instance_shape          = "VM.Standard.E2.1.Micro"
instance_ocpus          = 1
instance_memory_in_gbs  = 1

# For ARM flex instance
instance_shape          = "VM.Standard.A1.Flex"
instance_ocpus          = 4
instance_memory_in_gbs  = 24
```

### Changing the Network Configuration

Edit variables in `terraform.tfvars`:

```hcl
vcn_cidr_block    = "10.0.0.0/16"
subnet_cidr_block = "10.0.1.0/24"
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete the instance and all data on it!

## Troubleshooting

### "Service limit exceeded"

Free tier limits:
- ARM: 4 OCPUs, 24GB RAM total
- x86: 2 micro instances
- Storage: 200GB total

Check your current usage in OCI Console.

### "Image not found"

The configuration automatically finds the latest Ubuntu 22.04 image for your region and shape. If this fails:

1. Verify your region supports the selected shape
2. Check if Ubuntu images are available in your region
3. Try a different shape (ARM vs x86)

### "Authorization failed"

1. Verify your API key is correct
2. Check the private key path in `terraform.tfvars`
3. Ensure the private key file has correct permissions (600)
4. Verify your user has permissions in the compartment

## Security Considerations

This configuration creates:
- Security list allowing ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
- Public subnet with internet gateway
- SSH key-based authentication (password auth disabled)

For production:
- Consider using a bastion host
- Implement network security groups
- Use private subnets where possible
- Enable OCI Cloud Guard
- Set up VPN or FastConnect for sensitive access

## Next Steps

After Terraform completes:

1. Note the instance public IP
2. Configure your domain's DNS to point to this IP
3. Run the Ansible playbook to deploy Stoat:
   ```bash
   cd ../ansible
   ansible-playbook playbook.yml -e "domain_name=your.domain.com"
   ```

## More Information

See the main [DEPLOYMENT.md](../DEPLOYMENT.md) for complete deployment instructions.

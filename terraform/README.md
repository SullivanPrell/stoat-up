# Terraform Configuration for OCI

This directory contains Terraform configuration to provision infrastructure on Oracle Cloud Infrastructure (OCI) for deploying Stoat.

## Files

- `main.tf` - Main Terraform configuration (VCN, compute instance, security)
- `variables.tf` - Variable definitions
- `outputs.tf` - Output values (IP address, instance ID, etc.)
- `terraform.tfvars.example` - Example variables file
- `cloud-init.yaml` - Cloud-init configuration for instance
- `inventory.tpl` - Template for Ansible inventory file

## Quick Start

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your OCI credentials and settings

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## OCI Free Tier Configuration

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

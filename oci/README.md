# OCI Deployment for stoat-up

This directory contains the automation to deploy the `stoat-up` service to Oracle Cloud Infrastructure (OCI) on the Always Free Tier.

The automation uses a combination of Makefile, Terraform, and Ansible to provision infrastructure and configure the service.

## Prerequisites

Before you begin, you will need:

1.  An Oracle Cloud Infrastructure (OCI) account.
2.  A Cloudflare account managing your domain.
3.  [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed locally.
4.  [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) installed locally.
5.  An SSH key pair. If you don't have one, you can generate it with `ssh-keygen -t rsa -b 4096`.

## Configuration

1.  **Copy the example environment file:**
    ```bash
    cp .env.example .env
    ```

2.  **Edit the `.env` file:**
    Open the `.env` file and fill in the values for your OCI and Cloudflare accounts.

    *   `TF_VAR_tenancy_ocid`: Your OCI tenancy OCID.
    *   `TF_VAR_user_ocid`: Your OCI user OCID.
    *   `TF_VAR_fingerprint`: The fingerprint of your OCI API key.
    *   `TF_VAR_private_key_path`: The absolute path to your OCI private key file (e.g., `/Users/youruser/.oci/oci_api_key.pem`).
    *   `TF_VAR_region`: The OCI region you want to deploy to (e.g., `us-ashburn-1`).
    *   `TF_VAR_compartment_ocid`: The OCID of the compartment where you want to create the resources.
    *   `CLOUDFLARE_EMAIL`: Your Cloudflare account email.
    *   `CLOUDFLARE_API_KEY`: Your Cloudflare Global API Key.
    *   `CLOUDFLARE_ZONE_ID`: The Zone ID for your domain in Cloudflare.
    *   `TF_VAR_domain`: The domain you want to use for the service.

## Usage

The deployment process is managed through the `Makefile` in the root of the project.

### Plan the deployment

To see what resources Terraform will create, run:

```bash
make plan
```

### Deploy the infrastructure and configure the service

To provision the infrastructure with Terraform and configure the services with Ansible, run:

```bash
make all
```
or
```bash
make configure
```

This command will:
1.  Run `terraform apply` to create the OCI resources (VCN, instance, etc.) and the Cloudflare DNS record.
2.  Run the Ansible playbook to:
    *   Install common packages.
    *   Install and configure Caddy as a reverse proxy.
    *   Install Docker and Docker Compose.
    *   Copy the application files and `.env` file to the server.
    *   Start the application using `docker-compose`.

### Destroy the deployment

To tear down all the resources created by Terraform, run:

```bash
make destroy
```

This will remove the compute instance, VCN, and other resources from OCI, as well as the DNS record from Cloudflare.

## File Structure

*   `Makefile`: Orchestrates the entire process.
*   `.env.example`: Template for environment variables.
*   `terraform/`: Contains all Terraform configuration files.
*   `ansible/`: Contains all Ansible configuration files.
    *   `inventory/`: Ansible inventory files (including the dynamic inventory script for OCI).
    *   `playbooks/`: The main Ansible playbook.
    *   `roles/`: Ansible roles for `common`, `caddy`, and the `app`.
*   `oci/`: This directory, containing documentation.

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "tenancy_ocid" {
  description = "OCID of your tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user calling the API"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint for the key pair being used"
  type        = string
}

variable "private_key_path" {
  description = "Path to your private key"
  type        = string
}

variable "config_file_profile" {
  description = "OCI CLI config file profile"
  type        = string
  default     = "DEFAULT"
}

variable "compartment_ocid" {
  description = "OCID of the compartment to create resources in"
  type        = string
}

variable "vcn_cidr_block" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_shape" {
  description = "Shape for compute instance (Free tier: VM.Standard.E2.1.Micro or VM.Standard.A1.Flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs (up to 4 total across all instances on free tier)"
  type        = number
  default     = 2
}

variable "instance_memory_in_gbs" {
  description = "Amount of memory in GB (up to 24GB total across all instances on free tier)"
  type        = number
  default     = 12
}

variable "boot_volume_size_in_gbs" {
  description = "Size of boot volume in GB (up to 200GB total on free tier)"
  type        = string
  default     = "50"
}

variable "instance_name" {
  description = "Display name for the instance"
  type        = string
  default     = "stoat-server"
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the Stoat instance"
  type        = string
}

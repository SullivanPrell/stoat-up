variable "tenancy_ocid" {
  description = "The OCID of the tenancy."
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user."
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key."
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file."
  type        = string
}

variable "region" {
  description = "The OCI region to deploy to."
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment."
  type        = string
}

variable "cloudflare_email" {
  description = "The email for the Cloudflare account."
  type        = string
  sensitive   = true
}

variable "cloudflare_api_key" {
  description = "The API key for the Cloudflare account."
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "The Zone ID of the domain in Cloudflare."
  type        = string
}

variable "domain" {
  description = "The domain name to use."
  type        = string
}

variable "app_name" {
  description = "The name of the application."
  type        = string
  default     = "stoat-up"
}

variable "ssh_public_key" {
  description = "The public SSH key to use for the compute instance."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

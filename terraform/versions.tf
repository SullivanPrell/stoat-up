terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

# Network
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}-vcn"
  cidr_block     = "10.0.0.0/16"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.app_name}-ig"
  vcn_id         = oci_core_vcn.main.id
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-rt"
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_subnet" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.app_name}-subnet"
  cidr_block     = "10.0.1.0/24"
  route_table_id = oci_core_route_table.main.id
  security_list_ids = [oci_core_security_list.main.id]
}

resource "oci_core_security_list" "main" {
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.main.id
    display_name = "${var.app_name}-sl"

    egress_security_rules {
        protocol = "all"
        destination = "0.0.0.0/0"
    }

    ingress_security_rules {
        protocol = "6" # TCP
        source = "0.0.0.0/0"
        tcp_options {
            min = 22
            max = 22
        }
    }

    ingress_security_rules {
        protocol = "6" # TCP
        source = "0.0.0.0/0"
        tcp_options {
            min = 80
            max = 80
        }
    }

    ingress_security_rules {
        protocol = "6" # TCP
        source = "0.0.0.0/0"
        tcp_options {
            min = 443
            max = 443
        }
    }
}

# Compute
data "oci_core_images" "ubuntu" {
    compartment_id = var.compartment_ocid
    operating_system = "Canonical Ubuntu"
    operating_system_version = "22.04"
    shape = "VM.Standard.A1.Flex"
    sort_by = "TIMECREATED"
    sort_order = "DESC"
}

resource "oci_core_instance" "main" {
  compartment_id      = var.compartment_ocid
  display_name        = "${var.app_name}-instance"
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    ocpus = 1
    memory_in_gbs = 6
  }
  create_vnic_details {
    subnet_id = oci_core_subnet.main.id
    assign_public_ip = true
  }
  source_details {
    source_id   = data.oci_core_images.ubuntu.images[0].id
    source_type = "image"
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key)
  }
}

# DNS
resource "cloudflare_record" "main" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  value   = oci_core_instance.main.public_ip
  type    = "A"
  proxied = true
}

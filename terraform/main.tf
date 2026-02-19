terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "oci" {
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  user_ocid           = var.user_ocid
  fingerprint         = var.fingerprint
  private_key_path    = var.private_key_path
  config_file_profile = var.config_file_profile
}

# Get the availability domain
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# Get the latest Ubuntu image for the region
data "oci_core_images" "ubuntu_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Create VCN (Virtual Cloud Network)
resource "oci_core_vcn" "stoat_vcn" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = var.compartment_ocid
  display_name   = "stoat-vcn"
  dns_label      = "stoatvcn"
}

# Create Internet Gateway
resource "oci_core_internet_gateway" "stoat_ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.stoat_vcn.id
  display_name   = "stoat-internet-gateway"
  enabled        = true
}

# Create Route Table
resource "oci_core_route_table" "stoat_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.stoat_vcn.id
  display_name   = "stoat-route-table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.stoat_ig.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# Create Security List
resource "oci_core_security_list" "stoat_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.stoat_vcn.id
  display_name   = "stoat-security-list"

  # Allow outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Allow all outbound traffic"
  }

  # Allow SSH (22)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "Allow SSH"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow HTTP (80)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "Allow HTTP"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Allow HTTPS (443)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "Allow HTTPS"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

# Create Subnet
resource "oci_core_subnet" "stoat_subnet" {
  cidr_block                 = var.subnet_cidr_block
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.stoat_vcn.id
  display_name               = "stoat-subnet"
  dns_label                  = "stoatsubnet"
  route_table_id             = oci_core_route_table.stoat_route_table.id
  security_list_ids          = [oci_core_security_list.stoat_security_list.id]
  prohibit_public_ip_on_vnic = false
}

# Create Compute Instance
resource "oci_core_instance" "stoat_instance" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_name
  shape               = var.instance_shape

  # For free tier ARM instances
  shape_config {
    memory_in_gbs = var.instance_memory_in_gbs
    ocpus         = var.instance_ocpus
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.stoat_subnet.id
    display_name     = "stoat-vnic"
    assign_public_ip = true
    hostname_label   = "stoat"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_images.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      hostname = var.domain_name
    }))
  }

  preserve_boot_volume = false

  lifecycle {
    ignore_changes = [
      source_details[0].source_id
    ]
  }
}

# Create a dynamic inventory file for Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    instance_ip = oci_core_instance.stoat_instance.public_ip
  })
  filename = "${path.root}/../ansible/inventory.ini"
}

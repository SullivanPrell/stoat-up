output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.stoat_instance.public_ip
}

output "instance_id" {
  description = "OCID of the instance"
  value       = oci_core_instance.stoat_instance.id
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.stoat_vcn.id
}

output "subnet_id" {
  description = "OCID of the subnet"
  value       = oci_core_subnet.stoat_subnet.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${oci_core_instance.stoat_instance.public_ip}"
}

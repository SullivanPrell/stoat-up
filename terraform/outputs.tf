output "instance_public_ip" {
  description = "The public IP address of the compute instance."
  value       = oci_core_instance.main.public_ip
}

output "instance_id" {
  description = "The OCID of the compute instance."
  value       = oci_core_instance.main.id
}

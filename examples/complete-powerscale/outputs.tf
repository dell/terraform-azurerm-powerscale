/*

        Copyright (c) 2024 Dell Inc. or its subsidiaries. All rights reserved.

*/

# Azure resource lists
output "internal_nics" {
  value = module.powerscale.internal_nics
}

output "internal_ip_addresses" {
  value = module.powerscale.internal_ip_addresses
}

output "external_nics" {
  value = module.powerscale.external_nics
}

output "external_ip_addresses" {
  value = module.powerscale.external_ip_addresses
}

output "cluster_id" {
  description = "Cluster ID"
  value       = module.powerscale.cluster_id
}

output "first_node_external_ip_address" {
  description = "External IP address of the first node"
  value       = module.powerscale.first_node_external_ip_address
}

output "first_node_instance_name" {
  description = "First node instance name"
  value       = module.powerscale.first_node_instance_name
}

output "first_node_instance_id" {
  description = "First node instance ID"
  value       = module.powerscale.first_node_instance_id
}

output "disk_encryption_set_id" {
  description = "Disk encryption set id"
  value       = module.powerscale.encryption_set
}

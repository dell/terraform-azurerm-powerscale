/*

        Copyright (c) 2024 Dell Inc. or its subsidiaries. All rights reserved.

*/

# Azure resource lists

output "cluster_id" {
  description = "A unique identifier for PowerScale Cluster."
  value       = local.internal_cluster_id
}

output "first_node_instance_name" {
  description = "The First node instance name."
  value       = azurerm_resource_group_template_deployment.azonefs_node[0].name
}

output "first_node_instance_id" {
  description = "The First node instance ID."
  value       = azurerm_resource_group_template_deployment.azonefs_node[0].id
}


output "first_node_external_ip_address" {
  description = "The external IP address of the first node."
  value       = azurerm_network_interface.azonefs_network_interface_external[0].ip_configuration[0].private_ip_address
}

output "external_ip_addresses" {
  description = "A list of external IP addresses for all nodes."
  value       = azurerm_network_interface.azonefs_network_interface_external[*].ip_configuration[0].private_ip_address
}

output "internal_ip_addresses" {
  description = "A list of internal IP addresses for all nodes."
  value       = azurerm_network_interface.azonefs_network_interface_internal[*].ip_configuration[0].private_ip_address
}

output "internal_nics" {
  description = "A list of IDs for internal network interfaces."
  value       = azurerm_network_interface.azonefs_network_interface_internal[*].id
}

output "external_nics" {
  description = "A list of IDs for external network interfaces."
  value       = azurerm_network_interface.azonefs_network_interface_external[*].id
}

output "encryption_set" {
  description = "The full ID of the disk encryption set."
  value       = data.azurerm_disk_encryption_set.azonefs_disk_encryption_set[*].id
}

output "join_mode" {
  description = "The join mode for the cluster."
  value       = var.join_mode
}
/*

        Copyright (c) 2024 Dell Inc. or its subsidiaries. All rights reserved.

*/

/* Create a PowerScale Cluster in Azure */
module "powerscale" {
  source                      = "../.."
  subscription_id             = var.subscription_id
  image_id                    = var.image_id
  cluster_name                = var.cluster_name
  cluster_nodes               = var.cluster_nodes
  max_num_nodes               = var.max_num_nodes
  node_size                   = var.node_size
  os_disk_type                = var.os_disk_type
  data_disk_type              = var.data_disk_type
  data_disk_size              = var.data_disk_size
  data_disks_per_node         = var.data_disks_per_node
  smartconnect_zone           = var.smartconnect_zone
  external_nsg_name           = var.external_nsg_name
  external_nsg_resource_group = var.external_nsg_resource_group
  external_subnet_name        = var.external_subnet_name
  # kics-scan ignore-line
  hashed_root_passphrase = var.hashed_root_passphrase == null ? var.default_hashed_password : var.hashed_root_passphrase
  # kics-scan ignore-line
  hashed_admin_passphrase            = var.hashed_admin_passphrase == null ? var.default_hashed_password : var.hashed_admin_passphrase
  internal_nsg_name                  = var.internal_nsg_name
  internal_nsg_resource_group        = var.internal_nsg_resource_group
  internal_subnet_name               = var.internal_subnet_name
  network_id                         = var.network_id
  resource_group                     = var.resource_group
  use_disk_encryption                = var.use_disk_encryption
  disk_encryption_set_name           = var.disk_encryption_set_name
  disk_encryption_set_resource_group = var.disk_encryption_set_resource_group
  resource_tags                      = var.resource_tags
  identity_list                      = var.identity_list
}

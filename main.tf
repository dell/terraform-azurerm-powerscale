/*

        Copyright (c) 2024 Dell Inc. or its subsidiaries. All rights reserved.

*/

/**
 Main terraform Script to deploy PowerScale Cluster in Azure
*/


provider "azurerm" {
  resource_provider_registrations = "none"
  subscription_id                 = var.subscription_id
  partner_id                      = "e9a925ea-0642-4181-a666-074fb79f1aa1"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azapi" {
  subscription_id = var.subscription_id
}


terraform {
  required_providers {
    azurerm = {
      version = "4.18.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">=1.12"
    }
  }
}


locals {
  # the only place network_id_fields is used is in in azonefs_virtual_network
  network_id_fields   = regex("/subscriptions/(?P<subscription_id>[^/]+)/resourceGroups/(?P<resource_group>[^/]+)/providers/Microsoft.Network/virtualNetworks/(?P<name>.+)", var.network_id)
  internal_cluster_id = var.cluster_id != null ? var.cluster_id : var.cluster_name

  # Hack to get around Terraform's type system to handle multiple user identities in vm.json
  id_type  = length(var.identity_list) == 0 ? "None" : "UserAssigned"
  ids      = { "type" = local.id_type, "userAssignedIdentities" = { for i in var.identity_list : i => {} } }
  identity = { for k, v in local.ids : k => v if v != {} }

  resource_group_name = var.resource_group
  serial_numbers      = [for node_number in range(var.cluster_nodes) : "SV200-930073-${format("%04d", node_number)}"]
}

resource "azurerm_proximity_placement_group" "azonefs_proximity_placement_group" {
  name                = "${local.internal_cluster_id}-proximity-placement-group"
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = var.resource_tags
}

resource "azurerm_availability_set" "azonefs_aset" {
  name                         = "${local.internal_cluster_id}-aset"
  location                     = var.location
  resource_group_name          = local.resource_group_name
  proximity_placement_group_id = azurerm_proximity_placement_group.azonefs_proximity_placement_group.id
  platform_update_domain_count = var.update_domain_count
  platform_fault_domain_count  = 2
  tags                         = var.resource_tags
}

data "azurerm_disk_encryption_set" "azonefs_disk_encryption_set" {
  count               = var.use_disk_encryption ? 1 : 0
  name                = var.disk_encryption_set_name
  resource_group_name = var.disk_encryption_set_resource_group
}

resource "azurerm_network_interface" "azonefs_network_interface_internal" {
  count                          = var.cluster_nodes
  name                           = "${local.internal_cluster_id}-${count.index + 1}-network-interface-internal"
  location                       = var.location
  resource_group_name            = local.resource_group_name
  accelerated_networking_enabled = true
  tags                           = var.resource_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.internal_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.internal_prefix, count.index + var.addr_range_offset)
  }

  lifecycle {
    ignore_changes = [tags, ip_configuration]
  }
}

resource "azurerm_network_interface" "azonefs_network_interface_external" {
  count                          = var.cluster_nodes
  name                           = "${local.internal_cluster_id}-${count.index + 1}-network-interface-external"
  location                       = var.location
  resource_group_name            = local.resource_group_name
  accelerated_networking_enabled = true
  tags                           = var.resource_tags

  ip_configuration {
    name                          = "external"
    subnet_id                     = var.external_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.external_prefix, count.index + var.addr_range_offset)
    primary                       = true
  }

  dynamic "ip_configuration" {
    for_each = lookup(var.external_secondary_ip.customer, count.index, [])
    content {
      name                          = "external_secondary${ip_configuration.key}"
      subnet_id                     = var.external_subnet_id
      private_ip_address_allocation = "Static"
      private_ip_address            = ip_configuration.value
      primary                       = false
    }
  }
  lifecycle {
    ignore_changes = [tags, ip_configuration]
  }
  # TODO: management secondary IPs when management subnet is added
}

/**
  The following local .tftpl files are used to:
  - calculate network information for the created network interfaces
  - Hash passwords for created powerscale cluster
*/
locals {
  mids = [for node_number in range(var.cluster_nodes) : jsondecode(
    templatefile("${path.module}/machineid.tftpl", {
    serial_number = local.serial_numbers[node_number] })
  )]

  acs = jsondecode(
    templatefile(
      "${path.module}/acs.tftpl", {
        addr_range_offset        = var.addr_range_offset,
        cluster_name             = var.cluster_name,
        cluster_nodes            = var.cluster_nodes,
        dns_domains              = var.dns_domains,
        dns_servers              = var.dns_servers,
        external_gateway_address = var.external_gateway_address == null ? cidrhost(var.external_prefix, 1) : var.external_gateway_address,
        external_prefix          = var.external_prefix,
        internal_gateway_address = var.internal_gateway_address == null ? cidrhost(var.internal_prefix, 1) : var.internal_gateway_address,
        internal_prefix          = var.internal_prefix
        max_num_nodes            = var.max_num_nodes
        hashed_root_password     = var.hashed_root_passphrase,
        hashed_admin_password    = var.hashed_admin_passphrase,
        smartconnect_zone        = var.smartconnect_zone,
        join_mode                = var.join_mode,
        post_install_commands    = length(var.post_install_commands) > 0 ? join(" ; ", var.post_install_commands) : "isi status"
        serial_numbers           = local.serial_numbers
      }
    )
  )
}
locals {
  image_reference = (
    var.image_type == "marketplace" ? var.marketplace_image[var.marketplace] :
    var.image_type == "managed_image" ? {
      id = var.image_id
    } : {}
  )
  marketplace_image_plan = var.image_type == "marketplace" ? {
    publisher = var.marketplace_image[var.marketplace].publisher
    product   = var.marketplace_image[var.marketplace].offer
    name      = var.marketplace_image[var.marketplace].sku
  } : {}
}
/**
  The following resouce uses the vm.json file which contains properties for deploying an azure VM.
*/
resource "azurerm_resource_group_template_deployment" "azonefs_node" {
  count               = var.cluster_nodes
  name                = join("-", [substr(local.internal_cluster_id, 0, 20), uuid(), count.index])
  resource_group_name = local.resource_group_name
  deployment_mode     = "Incremental"
  template_content    = file("${path.module}/vm.json")
  tags                = var.resource_tags
  parameters_content = jsonencode({
    "name" : {
      value = "${local.internal_cluster_id}-node-${count.index + 1}" # Increment by 1 to match PowerScale LNN naming scheme
    },
    "location" : {
      value = var.location
    },
    "sku" : {
      value = var.node_size
    },
    "os_disk_type" : {
      value = var.os_disk_type
    },
    "data_disk_type" : {
      value = var.data_disk_type
    },
    "data_disk_size" : {
      value = var.data_disk_size
    },
    "data_disk_count" : {
      value = var.data_disks_per_node
    },
    "avset_id" : {
      value = azurerm_availability_set.azonefs_aset.id
    },
    "ppg_id" : {
      value = azurerm_proximity_placement_group.azonefs_proximity_placement_group.id
    },
    "image_reference" : {
      value = local.image_reference
    },
    "marketplace_image_plan" : {
      value = local.marketplace_image_plan
    },
    "user_data" : {
      value = base64encode(count.index != 0 ? jsonencode(local.mids[count.index]) : jsonencode(merge(local.mids[0], local.acs)))
    },
    "nic_ids" = {
      value = concat(
        [
          {
            id         = azurerm_network_interface.azonefs_network_interface_external[count.index].id
            properties = { primary = true, deleteOption = "Detach" }
          },
          {
            id         = azurerm_network_interface.azonefs_network_interface_internal[count.index].id
            properties = { primary = false, deleteOption = "Detach" }
          }
        ]
      )
    },
    "resourceTags" : {
      value = var.resource_tags
    },
    "disk_encryption_set_id" : {
      value = var.use_disk_encryption ? data.azurerm_disk_encryption_set.azonefs_disk_encryption_set[0].id : "noencryption"
    },
    "identity" : {
      value = local.identity
    }
  })

  lifecycle {
    ignore_changes = [name]
    precondition {
      condition     = var.cluster_nodes <= 18 && var.cluster_nodes <= var.max_num_nodes
      error_message = "PowerScale maximum number of nodes must be specified at cluster creation time and cannot scale more than 18 nodes."
    }
  }

  depends_on = [
    azurerm_network_interface.azonefs_network_interface_external,
    azurerm_network_interface.azonefs_network_interface_internal,
    azurerm_proximity_placement_group.azonefs_proximity_placement_group,
    azurerm_availability_set.azonefs_aset
  ]
}

resource "azapi_update_resource" "os_disk_network_access" {
  count       = var.cluster_nodes
  type        = "Microsoft.Compute/disks@2024-03-02"
  resource_id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Compute/disks/${local.internal_cluster_id}-node-${count.index + 1}-osdisk"

  body = {
    properties = {
      networkAccessPolicy = "DenyAll"
      publicNetworkAccess = "Disabled"
    }
  }

  depends_on = [
    azurerm_resource_group_template_deployment.azonefs_node
  ]
}

resource "azapi_update_resource" "data_disk_network_access" {
  for_each = toset(flatten([
    for node in range(var.cluster_nodes) : [
      for disk in range(var.data_disks_per_node) :
      "${local.internal_cluster_id}-node-${node + 1}-data-${disk + 1}"
    ]
  ]))
  type        = "Microsoft.Compute/disks@2024-03-02"
  resource_id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Compute/disks/${each.value}"

  body = {
    properties = {
      networkAccessPolicy = "DenyAll"
      publicNetworkAccess = "Disabled"
    }
  }

  depends_on = [
    azurerm_resource_group_template_deployment.azonefs_node
  ]
}

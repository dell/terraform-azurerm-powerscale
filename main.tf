/*

        Copyright (c) 2024 Dell Inc. or its subsidiaries. All rights reserved.

*/

/**
 Main terraform Script to deploy PowerScale Cluster in Azure
*/


provider "azurerm" {
  skip_provider_registration = true
  subscription_id            = var.subscription_id
  partner_id                 = "e9a925ea-0642-4181-a666-074fb79f1aa1"
  #features {}
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

locals {
  network_id_fields   = regex("/subscriptions/(?P<subscription_id>[^/]+)/resourceGroups/(?P<resource_group>[^/]+)/providers/Microsoft.Network/virtualNetworks/(?P<name>.+)", var.network_id)
  internal_cluster_id = var.cluster_id != null ? var.cluster_id : var.cluster_name

  # Hack to get around Terraform's type system to handle multiple user identities in vm.json
  id_type  = length(var.identity_list) == 0 ? "None" : "UserAssigned"
  ids      = { "type" = local.id_type, "userAssignedIdentities" = { for i in var.identity_list : i => {} } }
  identity = { for k, v in local.ids : k => v if v != {} }
}


data "azurerm_resource_group" "azonefs_resource_group" {
  name = var.resource_group != null ? var.resource_group : "${local.internal_cluster_id}-resource-group"
  #name = azurerm_resource_group.rg.name != null ? azurerm_resource_group.rg.name : "${local.internal_cluster_id}-resource-group"
}

resource "azurerm_proximity_placement_group" "azonefs_proximity_placement_group" {
  name                = "${local.internal_cluster_id}-proximity-placement-group"
  location            = data.azurerm_resource_group.azonefs_resource_group.location
  resource_group_name = data.azurerm_resource_group.azonefs_resource_group.name
  tags                = var.resource_tags
}

resource "azurerm_availability_set" "azonefs_aset" {
  name                         = "${local.internal_cluster_id}-aset"
  location                     = data.azurerm_resource_group.azonefs_resource_group.location
  resource_group_name          = data.azurerm_resource_group.azonefs_resource_group.name
  proximity_placement_group_id = azurerm_proximity_placement_group.azonefs_proximity_placement_group.id
  platform_update_domain_count = var.update_domain_count
  platform_fault_domain_count  = 2
  tags                         = var.resource_tags
}

data "azurerm_virtual_network" "azonefs_virtual_network" {
  name                = local.network_id_fields.name
  resource_group_name = local.network_id_fields.resource_group
}

data "azurerm_subnet" "azonefs_internal_subnet" {
  name                 = var.internal_subnet_name
  resource_group_name  = data.azurerm_virtual_network.azonefs_virtual_network.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.azonefs_virtual_network.name
}

data "azurerm_subnet" "azonefs_external_subnet" {
  name                 = var.external_subnet_name
  resource_group_name  = data.azurerm_virtual_network.azonefs_virtual_network.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.azonefs_virtual_network.name
}

locals {
  internal_prefix = data.azurerm_subnet.azonefs_internal_subnet.address_prefixes[0]
  external_prefix = data.azurerm_subnet.azonefs_external_subnet.address_prefixes[0]
}

data "azurerm_network_security_group" "azonefs_internal_network_security_group" {
  name                = var.internal_nsg_name
  resource_group_name = var.internal_nsg_resource_group
}

data "azurerm_network_security_group" "azonefs_external_network_security_group" {
  name                = var.external_nsg_name
  resource_group_name = var.external_nsg_resource_group
}

data "azurerm_disk_encryption_set" "azonefs_disk_encryption_set" {
  count               = var.use_disk_encryption ? 1 : 0
  name                = var.disk_encryption_set_name
  resource_group_name = var.disk_encryption_set_resource_group
}

resource "azurerm_network_interface" "azonefs_network_interface_internal" {
  count                          = var.cluster_nodes
  name                           = "${local.internal_cluster_id}-${count.index + 1}-network-interface-internal"
  location                       = data.azurerm_virtual_network.azonefs_virtual_network.location
  resource_group_name            = data.azurerm_resource_group.azonefs_resource_group.name
  accelerated_networking_enabled = true
  tags                           = var.resource_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.azonefs_internal_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(local.internal_prefix, count.index + var.addr_range_offset)
  }

  lifecycle {
    ignore_changes = [tags, ip_configuration]
  }
}

resource "azurerm_network_interface_security_group_association" "azonefs_network_interface_internal_nsg_association" {
  count                     = var.cluster_nodes
  network_interface_id      = azurerm_network_interface.azonefs_network_interface_internal[count.index].id
  network_security_group_id = data.azurerm_network_security_group.azonefs_internal_network_security_group.id
  # The depends_one is needed if we don't define a network security rule. Otherwise Terraform will attempt to
  # create this association before it creates the network security group which leads to an error.
  depends_on = [
    azurerm_network_interface.azonefs_network_interface_internal
  ]
}

resource "azurerm_network_interface" "azonefs_network_interface_external" {
  count                          = var.cluster_nodes
  name                           = "${local.internal_cluster_id}-${count.index + 1}-network-interface-external"
  location                       = data.azurerm_virtual_network.azonefs_virtual_network.location
  resource_group_name            = data.azurerm_resource_group.azonefs_resource_group.name
  accelerated_networking_enabled = true
  tags                           = var.resource_tags

  ip_configuration {
    name                          = "external"
    subnet_id                     = data.azurerm_subnet.azonefs_external_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(local.external_prefix, count.index + var.addr_range_offset)
    primary                       = true
  }

  dynamic "ip_configuration" {
    for_each = lookup(var.external_secondary_ip.customer, count.index, [])
    content {
      name                          = "external_secondary${ip_configuration.key}"
      subnet_id                     = data.azurerm_subnet.azonefs_external_subnet.id
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

resource "azurerm_network_interface_security_group_association" "azonefs_network_interface_external_nsg_association" {
  count                     = var.cluster_nodes
  network_interface_id      = azurerm_network_interface.azonefs_network_interface_external[count.index].id
  network_security_group_id = data.azurerm_network_security_group.azonefs_external_network_security_group.id
  # The depends_one is needed if we don't define a network security rule. Otherwise Terraform will attempt to
  # create this association before it creates the network security group which leads to an error.
  depends_on = [
    azurerm_network_interface.azonefs_network_interface_external
  ]
}

/**
  The following local .tftpl files are used to:
  - calculate network information for the created network interfaces
  - Hash passwords for created powerscale cluster
*/
locals {
  mid = jsondecode(
    templatefile("${path.module}/machineid.tftpl", {})
  )

  acs = jsondecode(
    templatefile(
      "${path.module}/acs.tftpl", {
        addr_range_offset        = var.addr_range_offset,
        cluster_name             = var.cluster_name,
        cluster_nodes            = var.cluster_nodes,
        dns_domains              = var.dns_domains,
        dns_servers              = var.dns_servers,
        external_gateway_address = var.external_gateway_address == null ? cidrhost(local.external_prefix, 1) : var.external_gateway_address,
        external_prefix          = local.external_prefix,
        internal_gateway_address = var.internal_gateway_address == null ? cidrhost(local.internal_prefix, 1) : var.internal_gateway_address,
        internal_prefix          = local.internal_prefix
        max_num_nodes            = var.max_num_nodes
        hashed_root_password     = var.hashed_admin_passphrase,
        hashed_admin_password    = var.hashed_root_passphrase,
        smartconnect_zone        = var.smartconnect_zone,
        join_mode                = var.join_mode,
        post_install_commands    = length(var.post_install_commands) > 0 ? join(" ; ", var.post_install_commands) : "isi status"
      }
    )
  )
}

/**
  The following resouce uses the vm.json file which contains properties for deploying an azure VM.
*/
resource "azurerm_resource_group_template_deployment" "azonefs_node" {
  count               = var.cluster_nodes
  name                = join("-", [substr(local.internal_cluster_id, 0, 20), uuid(), count.index])
  resource_group_name = data.azurerm_resource_group.azonefs_resource_group.name
  deployment_mode     = "Incremental"
  template_content    = file("${path.module}/vm.json")
  tags                = var.resource_tags
  parameters_content = jsonencode({
    "name" : {
      value = "${local.internal_cluster_id}-node-${count.index + 1}" # Increment by 1 to match PowerScale LNN naming scheme
    },
    "location" : {
      value = data.azurerm_resource_group.azonefs_resource_group.location
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
    "image_id" : {
      value = var.image_id
    },
    "user_data" : {
      value = base64encode(count.index != 0 ? jsonencode(local.mid) : jsonencode(merge(local.mid, local.acs)))
    },
    "internal_nic_id" : {
      value = azurerm_network_interface.azonefs_network_interface_internal[count.index].id
    },
    "external_nic_id" : {
      value = azurerm_network_interface.azonefs_network_interface_external[count.index].id
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
      condition     = var.cluster_nodes <= 20 && var.cluster_nodes <= var.max_num_nodes
      error_message = "PowerScale maximum number of nodes must be specified at cluster creation time and cannot scale more than 20 nodes."
    }
  }

  depends_on = [
    azurerm_network_interface.azonefs_network_interface_external,
    azurerm_network_interface.azonefs_network_interface_internal,
    azurerm_proximity_placement_group.azonefs_proximity_placement_group,
    azurerm_availability_set.azonefs_aset,
    azurerm_network_interface_security_group_association.azonefs_network_interface_external_nsg_association,
    azurerm_network_interface_security_group_association.azonefs_network_interface_internal_nsg_association
  ]
}

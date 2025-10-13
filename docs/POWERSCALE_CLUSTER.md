<!--

        Copyright (c) 2023 Dell, Inc or its subsidiaries.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.

-->

## Introduction

This folder contains a [Terraform](https://www.terraform.io/) module that deploys a single node
[PowerScale](https://www.delltechnologies.com/partner/en-us/partner/powerscale.htm) cluster in the [Azure](https://azure.microsoft.com/en-us) platform. 

It provisions all the necessary resources required to deploy the cluster including the following:
1. [Proximity Placement Groups](https://learn.microsoft.com/en-us/azure/virtual-machines/co-location)
2. [Network interface(s)](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-network-interface?tabs=azure-portal)
3. [Availability Sets](https://learn.microsoft.com/en-us/azure/virtual-machines/availability-set-overview)
4. [Virtual Machine(s)](https://learn.microsoft.com/en-us/azure/virtual-machines/overview)
5. [Managed Disk(s)](https://learn.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview)


## Additional Components

The additional components which needs to be performed/deployed separately and are not included in this module are:
* [Resource Groups](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group)
* [Virtual Network](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
* [Virtual Network Subnets](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-subnet?tabs=azure-portal)
* [Network Security Groups](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
* [Disk Encryption ](https://learn.microsoft.com/en-us/azure/virtual-machines/disk-encryption)

## Requirements

### Azure PowerScale IAM Requirements

In order to create a PowerScale cluster in the Azure Public Cloud, an administrator must create a role with the following permissions.

```
[
  {
    "assignableScopes": [
      "/subscriptions/{subscriptionId1}"
    ],
    "description": "PowerScale cluster lifecycle role.",
    "id": "/subscriptions/{subscriptionId1}/providers/Microsoft.Authorization/roleDefinitions/pscaleliferole",
    "name": "pscaleliferole",
    "permissions": [
      {
        "actions": [
          "Microsoft.Resources/subscriptions/resourceGroups/read",
          "Microsoft.Resources/subscriptions/resourceGroups/write", # Only if we want to be able to create RGs from terraform.
          "Microsoft.Compute/availabilitySets/read",
          "Microsoft.Compute/availabilitySets/write",
          "Microsoft.Compute/availabilitySets/delete",
          "Microsoft.Compute/proximityPlacementGroups/read",
          "Microsoft.Compute/proximityPlacementGroups/write",
          "Microsoft.Compute/proximityPlacementGroups/delete",
          "Microsoft.Network/virtualNetworks/read",
          "Microsoft.Network/virtualNetworks/subnets/read",
          "Microsoft.Network/networkSecurityGroups/read",
          "Microsoft.Network/networkSecurityGroups/write",
          "Microsoft.Network/networkSecurityGroups/delete",
          #"Microsoft.Network/networkSecurityGroups/securityRules/read",
          #"Microsoft.Network/networkSecurityGroups/securityRules/write",
          #"Microsoft.Network/networkSecurityGroups/securityRules/delete",
          "Microsoft.Network/networkInterfaces/read",
          "Microsoft.Network/networkInterfaces/write",
          "Microsoft.Network/networkInterfaces/delete",
          "Microsoft.Compute/disks/read",
          "Microsoft.Compute/disks/write",
          "Microsoft.Compute/disks/delete"",
          "Microsoft.Compute/images/read",
          "Microsoft.Compute/virtualMachines/read",
          "Microsoft.Compute/virtualMachines/write",
          "Microsoft.Compute/virtualMachines/delete",
        ],
        "dataActions": [],
        "notActions": [],
        "notDataActions": []
      }
    ],
    "roleName": "PowerScale Cluster Lifecycle Operator",
    "roleType": "CustomRole",
    "type": "Microsoft.Authorization/roleDefinitions"
  }
]
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm (azure resource manager)](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) | 3.3.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_interface.azonefs_network_interface_external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.azonefs_network_interface_internal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.azonefs_network_interface_external_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_interface_security_group_association.azonefs_network_interface_internal_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.azonefs_network_security_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_proximity_placement_group.azonefs_proximity_placement_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/proximity_placement_group) | resource |
| [azurerm_resource_group.azonefs_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_storage_account.bootdiag_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_subnet.azonefs_external_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.azonefs_internal_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_machine.azonefs_node](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) | resource |
| [azurerm_virtual_network.azonefs_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| addr_range_offset | The offset into the address ranges where we will begin our IP ranges | `number` | `5` | no |
| cluster_admin_username | Default: "azonefs" | `string` | `"azonefs"` | no |
| cluster_id | n/a | `any` | `null` | no |
| cluster_name | Validation: length <= 40, regex pattern | `string` | n/a | yes |
| cluster_nodes | Default: 3, validation: <= 20 | `number` | `3` | yes |
| data_disk_size | Default: 12 | `number` | `12` | no |
| data_disk_type | Default: "Premium_LRS" | `string` | `"Premium_LRS"` | no |
| data_disks_per_node | Default: 3 | `number` | `3` | no |
| default_hashed_password | Type: string, sensitive, description: default hashed password | `string` | `null` | no |
| disk_encryption_set_name | Default: null | `string` | `null` | no |
| disk_encryption_set_resource_group | Default: null | `string` | `null` | no |
| dns_domains | n/a | `string` | `"c.daring-sunset-250103.internal"` | no |
| dns_servers | n/a | `string` | `"[ \"168.63.129.16\", \"169.254.169.254\"]"` | no |
| external_gateway_address | Default: null | `string` | `null` | no |
| external_nsg_name | Description: Name of external network security group | `string` | n/a | yes |
| external_nsg_resource_group | Description: Name of external network security group resource group | `string` | n/a | yes |
| external_subnet_name | Description: Name of external subnet | `string` | n/a | yes |
| external_secondary_ip | Type: object, default: {} | `object` | `{}` | no |
| hashed_admin_passphrase | Type: string, sensitive, description: admin user's hashed password | `string` | `null` | yes |
| hashed_root_passphrase | Type: string, sensitive, description: root user's hashed password | `string` | `null` | yes |
| identity_list | Description: List of resource id(s) that reference managed user-assigned identities, default: [] | `list` | `[]` | no |
| image_id | n/a | `string` | n/a | yes |
| internal_nsg_name | Description: Name of internal network security group | `string` | n/a | yes |
| internal_nsg_resource_group | Description: Name of internal network security group resource group | `string` | n/a | yes |
| internal_subnet_name | Description: Name of internal subnet | `string` | n/a | yes |
| max_num_nodes | Default: 20, validation: <= 20 | `number` | `20` | yes |
| network_id | n/a | `string` | n/a | yes |
| node_size | Default: "Standard_D8ds_v4" | `string` | `"Standard_D8ds_v4"` | no |
| os_disk_type | Default: "Premium_LRS" | `string` | `"Premium_LRS"` | no |
| resource_group | Default: null | `string` | `null` | yes |
| resource_tags | Type: map, default: {} | `map` | `{}` | no |
| smartconnect_zone | Description: FQDN to use as the DNS zone for SmartConnect, default: "" | `string` | `""` | no |
| subscription_id | n/a | `string` | n/a | yes |
| timezone | Default: "Greenwich Mean Time" | `string` | `"Greenwich Mean Time"` | no |
| update_domain_count | Default: 20 | `number` | `20` | no |
| use_disk_encryption | Description: Set to true to enable disk encryption using an existing disk encryption set | `bool` | `false` | no |
| post_install_commands | Description: List of commands to run after the installation | `list` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
|internal_nics | The list of internal NICS |
|internal_ip_addresses | The list of internal IP addresses list |
|external_nics | The list of external NICS |
|external_ip_addresses | The list of external IP addresses |
|cluster_id | The cluster ID |
|first_node_external_ip_address | The external IP address of the first node |
|first_node_instance_name | The name of the first node instance |
|first_node_instance_id | The ID of the first node instance |
|disk_encryption_set_id | The disk encryption set ID |


## Terraform Errors

If an error appears during the terraform apply stage, one of the below actions can be taken
* `terraform apply` : Run the `terraform apply` command to retry
* `terraform destroy` : To destroy all resources created from the `terraform apply` command
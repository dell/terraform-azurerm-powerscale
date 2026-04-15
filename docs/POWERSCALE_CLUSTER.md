<!--

        Copyright (c) 2023 Dell, Inc or its subsidiaries.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.

-->
This repository contains a [Terraform](https://www.terraform.io/) module, `main.tf`, that deploys a [PowerScale](https://www.delltechnologies.com/partner/en-us/partner/powerscale.htm) cluster in the [Azure](https://azure.microsoft.com/en-us) platform. 

## Table of contents

* [Introduction](#introduction)
* [Additional Components](#additional-components)
* [Requirements](#requirements)
  * [Azure PowerScale IAM Requirements](#azure-powerscale-iam-requirements)
* [Providers](#providers)
* [Resources](#resources)
* [Inputs](#inputs)
* [Outputs](#outputs)
* [Deploying a PowerScale Cluster in Azure](#deploying-a-powerscale-cluster-in-azure)
* [Terraform Errors](#terraform-errors)

## Introduction

The terraform module provisions all the necessary resources required to deploy the cluster including the following:
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
| <a name="provider_azurerm"></a> [azurerm (azure resource manager)](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) | 4.18.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_interface.azonefs_network_interface_external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.azonefs_network_interface_internal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
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
| <a name="input_addr_range_offset"></a> [addr\_range\_offset](#input\_addr\_range\_offset) | The offset into the address ranges where we will begin our IP ranges | `number` | `6` | no |
| <a name="input_cluster_admin_username"></a> [cluster\_admin\_username](#input\_cluster\_admin\_username) | The PowerScale Cluster administrator account name | `string` | `"azonefs"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | A unique identifier for PowerScale Cluster. Defaults to the cluster name if not specified. | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the PowerScale cluster | `string` | n/a | yes |
| <a name="input_cluster_nodes"></a> [cluster\_nodes](#input\_cluster\_nodes) | The number of nodes in the PowerScale cluster | `number` | `4` | no |
| <a name="input_data_disk_size"></a> [data\_disk\_size](#input\_data\_disk\_size) | The size of the data disks (GiB) | `number` | `512` | no |
| <a name="input_data_disk_type"></a> [data\_disk\_type](#input\_data\_disk\_type) | The Azure Managed Disk Type to be used for the Data disk | `string` | `"Standard_LRS"` | no |
| <a name="input_data_disks_per_node"></a> [data\_disks\_per\_node](#input\_data\_disks\_per\_node) | The number of data disks per node | `number` | `6` | no |
| <a name="input_disk_encryption_set_name"></a> [disk\_encryption\_set\_name](#input\_disk\_encryption\_set\_name) | The name of the disk encryption set to be used with VMs | `string` | `null` | no |
| <a name="input_disk_encryption_set_resource_group"></a> [disk\_encryption\_set\_resource\_group](#input\_disk\_encryption\_set\_resource\_group) | The resource group containing disk encryption set | `string` | `null` | no |
| <a name="input_dns_domains"></a> [dns\_domains](#input\_dns\_domains) | The DNS domain(s) for the PowerScale cluster. | `list(string)` | `[]` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | The list of DNS servers | `list(string)` | `"[ \"168.63.129.16\"]"` | no |
| <a name="input_external_gateway_address"></a> [external\_gateway\_address](#input\_external\_gateway\_address) | The external gateway address. If not specified, it defaults to the first IP address of the external subnet (cidrhost of external\_prefix) | `string` | `null` | no |
| <a name="input_external_prefix"></a> [external\_prefix](#input\_external\_prefix) | The prefix for the external subnet. | `string` | n/a | yes |
| <a name="input_external_secondary_ip"></a> [external\_secondary\_ip](#input\_external\_secondary\_ip) | Contains external secondary IP address configurations for customer and management traffic. | <pre>object({<br>    customer   = map(list(string))<br>    management = map(list(string))<br>  })</pre> | <pre>{<br>  "customer": {},<br>  "management": {}<br>}</pre> | no |
| <a name="input_external_subnet_id"></a> [external\_subnet\_id](#input\_external\_subnet\_id) | The value of the subnet ID for the external subnet. | `string` | n/a | yes |
| <a name="input_hashed_admin_passphrase"></a> [hashed\_admin\_passphrase](#input\_hashed\_admin\_passphrase) | The hashed admin passphrase to create the PowerScale cluster. SHA512 is the recommended hashing algorithm for this cluster | `string` | n/a | yes |
| <a name="input_hashed_root_passphrase"></a> [hashed\_root\_passphrase](#input\_hashed\_root\_passphrase) | The hashed admin passphrase to create the PowerScale cluster. | `string` | n/a | yes |
| <a name="input_identity_list"></a> [identity\_list](#input\_identity\_list) | The list of resource ID(s) that reference managed user-assigned identities | `list(string)` | `[]` | no |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | The Resource ID of the Azure Image | `string` | n/a | false |p
| <a name="input_image_type"></a> [image\_type](#input\_image\_type) | Which image source to use: marketplace \| managed\_image | `string` | `"marketplace"` | no |
| <a name="input_internal_gateway_address"></a> [internal\_gateway\_address](#input\_internal\_gateway\_address) | The internal gateway address. If not specified, it defaults to the first IP address of the internal subnet (cidrhost of internal\_prefix) | `string` | `null` | no |
| <a name="input_internal_prefix"></a> [internal\_prefix](#input\_internal\_prefix) | The prefix for the internal subnet. | `string` | n/a | yes |
| <a name="input_internal_subnet_id"></a> [internal\_subnet\_id](#input\_internal\_subnet\_id) | The value of the subnet ID for the internal subnet. | `string` | n/a | yes |
| <a name="input_join_mode"></a> [join\_mode](#input\_join\_mode) | Specifies how a node should join the cluster | `string` | `"auto"` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for the resource group, internal and external subnet. | `string` | n/a | yes |
| <a name="input_marketplace"></a> [marketplace](#input\_marketplace) | Which marketplace to use for image. Must match a key in marketplace\_image. | `string` | `"US"` | no |
| <a name="input_marketplace_image"></a> [marketplace\_image](#input\_marketplace\_image) | Marketplace image details. Required if image\_type = marketplace. | <pre>map(object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  }))</pre> | <pre>{<br>  "Canada": {<br>    "offer": "apexfilestoragecanada",<br>    "publisher": "dell-canada-inc",<br>    "sku": "apexfilestorage_cluster",<br>    "version": "latest"<br>  },<br>  "International": {<br>    "offer": "apexfilestorageeisi",<br>    "publisher": "dellemceisi123456",<br>    "sku": "apexfilestorage_cluster",<br>    "version": "latest"<br>  },<br>  "US": {<br>    "offer": "apexfilestorage",<br>    "publisher": "dellemc",<br>    "sku": "apexfilestorage_cluster",<br>    "version": "latest"<br>  }<br>}</pre> | no |
| <a name="input_max_num_nodes"></a> [max\_num\_nodes](#input\_max\_num\_nodes) | The max number of nodes we will scale up to | `number` | `18` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | The Resource ID of the Azure Virtual Network | `string` | n/a | yes |
| <a name="input_node_size"></a> [node\_size](#input\_node\_size) | The Azure Virtual Machine Size to be used for the node | `string` | `"Standard_D32ds_v5"` | no |
| <a name="input_os_disk_type"></a> [os\_disk\_type](#input\_os\_disk\_type) | The Azure Managed Disk Type to be used for the OS disk | `string` | `"Premium_LRS"` | no |
| <a name="input_post_install_commands"></a> [post\_install\_commands](#input\_post\_install\_commands) | The list of commands to run after the installation | `list(string)` | `[]` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | The name of the resource group. | `string` | `null` | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | The map of key-value pairs that will be applied to all resources as Azure Tags | `map(string)` | `{}` | no |
| <a name="input_smartconnect_zone"></a> [smartconnect\_zone](#input\_smartconnect\_zone) | The FQDN to use as the DNS zone for SmartConnect. | `string` | `""` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | The ID of the subscription | `string` | n/a | yes |
| <a name="input_update_domain_count"></a> [update\_domain\_count](#input\_update\_domain\_count) | The number of update domains for the availability set, which determines the grouping of virtual machines that can be restarted together during planned maintenance. | `number` | `20` | no |
| <a name="input_use_disk_encryption"></a> [use\_disk\_encryption](#input\_use\_disk\_encryption) | Set to true to enable VM disk encryption | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The ID of the cluster |
| <a name="output_encryption_set"></a> [encryption\_set](#output\_encryption\_set) | The full ID of the disk encryption set |
| <a name="output_external_ip_addresses"></a> [external\_ip\_addresses](#output\_external\_ip\_addresses) | A list of external IP addresses for all nodes |
| <a name="output_external_nics"></a> [external\_nics](#output\_external\_nics) | A list of IDs for external network interfaces |
| <a name="output_first_node_external_ip_address"></a> [first\_node\_external\_ip\_address](#output\_first\_node\_external\_ip\_address) | The external IP address of the first node |
| <a name="output_first_node_instance_id"></a> [first\_node\_instance\_id](#output\_first\_node\_instance\_id) | The ID of the first node instance |
| <a name="output_first_node_instance_name"></a> [first\_node\_instance\_name](#output\_first\_node\_instance\_name) | The name of the first node instance |
| <a name="output_internal_ip_addresses"></a> [internal\_ip\_addresses](#output\_internal\_ip\_addresses) | A list of internal IP addresses for all nodes |
| <a name="output_internal_nics"></a> [internal\_nics](#output\_internal\_nics) | A list of IDs for internal network interfaces |
| <a name="output_join_mode"></a> [join\_mode](#output\_join\_mode) | The join mode for the cluster |

## Deploying a PowerScale Cluster in Azure
### Variables

In the root directory, there is a template file called `terraform.tfvars.template`. Use this as the basis to create your own `terraform.tfvars` file.

There are required input variables that have been left blank which will need to be filled in.

### Admin and Root User Passwords

You can pass separate passwords for the root and admin user using `hashed_root_passphrase` and `hashed_admin_passphrase` respectively.

To get the hashed password you can use openssl-passwd utility.

<details>
<summary>Click to expand steps to generate hashed password</summary>

You can use the following commands to get the hashed password:

```shell
openssl passwd -6 -salt `head -c 8 /dev/random | xxd -p` "<replace-password-here>"
```

In the above command, `head -c 8 /dev/random | xxd -p` is used to generate an 8 byte random string in its hexadecimal representation which is used as the salt for producing the hashed output.
</details>

For the complete set of input variables that can be provided, check the `variables.tf` file.

### Disk Encryption

By enabling disk encryption via setting the `use_disk_encryption` input parameter to true, it is possible to use an existing disk encryption set in azure to encrypt both the OS disks and data disks created by terraform. Note that the name of the existing disk encryption set and the resource group it is located in will need to be added to the `disk_encryption_set_name` and `disk_encryption_set_resource_group` input parameters respectively.

### Connectivity

It is important to limit the connectivity on the internal vnet to only the other virtual nodes in the cluster.

### User-assigned Managed Identity

This is an optional input. By default, the `identity_list` input parameter is left empty. When specified, this allows the user to specify resource id(s) within a list that point to user-assigned identities within Azure.

### Deploy Terraform Module

```shell
terraform init
```

```shell
terraform apply -var-file=terraform.tfvars
```

## Terraform Errors

If an error appears during the terraform apply stage, one of the below actions can be taken
* `terraform apply` : Run the `terraform apply` command to retry
* `terraform destroy` : To destroy all resources created from the `terraform apply` command
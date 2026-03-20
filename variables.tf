/*

        Copyright (c) 2024 Dell Inc. or its subsidiaries. All rights reserved.

*/

# Old versions of terraform need to enable variable_validation
# so we can validate the passwords. New versions do not need this.
terraform {

}
variable "cluster_id" {
  type        = string
  default     = null
  description = "A unique identifier for PowerScale Cluster. Defaults to the cluster name if not specified."
  nullable    = true
}

variable "resource_group" {
  type        = string
  description = "The name of the existing resource group that the PowerScale cluster will be deployed to."
  nullable    = false
}

variable "network_id" {
  type        = string
  description = "The Resource ID of the Azure Virtual Network."
  validation {
    condition     = var.network_id != null
    error_message = "Please provide a valid Virtual Network Resource ID."
  }
  nullable = false
}

variable "node_size" {
  type        = string
  default     = "Standard_D32ds_v5"
  description = "The Azure Virtual Machine Size to be used for the node."
  nullable    = true
}

variable "cluster_name" {
  type        = string
  description = "The name of the PowerScale cluster."
  validation {
    condition     = length(var.cluster_name) <= 40 && can(regex("^[a-zA-Z]+[a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "The supplied cluster name must contain only numbers and letters starting with a letter and less than 41 characters."
  }
  nullable = false
}

variable "cluster_nodes" {
  type        = number
  default     = 4
  description = "The number of nodes in the PowerScale cluster."
  validation {
    condition     = var.cluster_nodes <= 18
    error_message = "PowerScale clusters on Azure must be less than or equal to 18 nodes."
  }
  nullable = true
}

variable "update_domain_count" {
  type        = number
  default     = 18
  description = "The number of update domains for the availability set, which determines the grouping of virtual machines that can be restarted together during planned maintenance."
  nullable    = true
}

variable "internal_gateway_address" {
  type        = string
  default     = null
  description = "The internal gateway address. If not specified, it defaults to the first IP address of the internal subnet (cidrhost of internal_prefix)."
  nullable    = true
}

variable "addr_range_offset" {
  type        = number
  default     = 6
  description = "The offset into the address ranges where we will begin our IP ranges."
  validation {
    condition     = var.addr_range_offset > 5
    error_message = "Azure reserves the first four IP addresses in subnets. The fifth will be reserved for the Smart Connect Service IP (SSIP). addr_range_offset must be > 5."
  }
  nullable = true
}

variable "max_num_nodes" {
  type        = number
  default     = 18
  description = "The max number of nodes we will scale up to."
  validation {
    condition     = var.max_num_nodes <= 18
    error_message = "PowerScale clusters on Azure must be less than or equal to 18 nodes."
  }
  nullable = true
}

variable "external_gateway_address" {
  type        = string
  default     = null
  description = "The external gateway address. If not specified, it defaults to the first IP address of the external subnet (cidrhost of external_prefix)."
  nullable    = true
}

variable "hashed_root_passphrase" {
  type        = string
  sensitive   = true
  description = "The hashed root passphrase to create the PowerScale cluster. SHA512 is the recommended hashing algorithm for this cluster."
  validation {
    condition     = var.hashed_root_passphrase != null
    error_message = "Please provide a valid hashed root password."
  }
  nullable = false
}

variable "hashed_admin_passphrase" {
  type        = string
  sensitive   = true
  description = "The hashed admin passphrase to create the PowerScale cluster. SHA512 is the recommended hashing algorithm for this cluster."
  validation {
    condition     = var.hashed_admin_passphrase != null
    error_message = "Please provide a valid hashed admin password."
  }
  nullable = false
}

variable "dns_servers" {
  type        = list(string)
  default     = ["168.63.129.16"]
  description = "The list of DNS servers."
  nullable    = true
}

variable "dns_domains" {
  type        = list(string)
  default     = []
  description = "The DNS domain(s) for the PowerScale cluster."
  validation {
    condition     = length(var.dns_domains) <= 6
    error_message = "A maximum of 6 DNS domains are accepted."
  }
  nullable = true
}

variable "smartconnect_zone" {
  type        = string
  default     = ""
  description = "The FQDN to use as the DNS zone for SmartConnect."
  validation {
    condition = (
      var.smartconnect_zone == "" ||
      can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.smartconnect_zone))
    )
    error_message = "Please enter a valid lowercase FQDN."
  }
  nullable = true
}

variable "resource_tags" {
  type        = map(string)
  default     = {}
  description = "The map of key-value pairs that will be applied to all resources as Azure Tags."
  nullable    = true
}

variable "os_disk_type" {
  type        = string
  default     = "Premium_LRS"
  description = "The Azure Managed Disk Type to be used for the OS disk."
  nullable    = true
}

variable "data_disk_type" {
  type        = string
  default     = "Standard_LRS"
  description = "The Azure Managed Disk Type to be used for the Data disk."
  nullable    = true
}

variable "data_disk_size" {
  type        = number
  default     = 512
  description = "The size of the data disks (GiB)."
  nullable    = true
}

variable "data_disks_per_node" {
  type        = number
  default     = 6
  description = "The number of data disks per node."
  nullable    = true
}

variable "external_secondary_ip" {
  type = object({
    customer   = map(list(string))
    management = map(list(string))
  })
  default = {
    customer   = {}
    management = {}
  }
  description = "Contains external secondary IP address configurations for customer and management traffic. If not specified, with with the managed identity, it will be created by the PowerScale cluster."
  nullable    = true
}

variable "identity_list" {
  type        = list(string)
  default     = []
  description = "The list of resource ID(s) that reference managed user-assigned identities."
  nullable    = false
}

variable "join_mode" {
  type        = string
  default     = "auto"
  description = "Specifies how a node should join the cluster."
  validation {
    condition     = contains(["auto", "manual", "secure"], var.join_mode)
    error_message = "Invalid join mode. Supported values are 'auto', 'manual', and 'secure'."
  }
  nullable = true
}

variable "use_disk_encryption" {
  type        = bool
  default     = false
  description = "Set to true to enable VM disk encryption."
  nullable    = true
}

variable "disk_encryption_set_name" {
  type        = string
  default     = null
  description = "The name of the disk encryption set to be used with VMs."
  validation {
    condition     = var.use_disk_encryption == false || var.disk_encryption_set_name != null
    error_message = "To enable disk encryption, you must specify a disk encryption set name."
  }
  nullable = true
}

variable "disk_encryption_set_resource_group" {
  type        = string
  default     = null
  description = "The resource group containing disk encryption set."
  validation {
    condition     = var.use_disk_encryption == false || var.disk_encryption_set_resource_group != null
    error_message = "To enable disk encryption, you must specify the resource group for the disk encryption set."
  }
  nullable = true
}

variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID."
  validation {
    condition     = var.subscription_id != null
    error_message = "Please provide a valid Azure subscription ID."
  }
  nullable = false
}


variable "image_type" {
  description = "Which image source to use: marketplace | managed_image"
  type        = string
  default     = "marketplace"
  validation {
    condition     = contains([for image in ["marketplace", "managed_image"] : lower(image)], lower(var.image_type))
    error_message = "image_type must be one of: marketplace or managed_image."
  }
}

variable "marketplace" {
  description = "Which marketplace to use for image. Must match a key in marketplace_image."
  type        = string
  default     = "US"
  validation {
    condition = lower(var.image_type) != "marketplace" || (
      var.marketplace != null &&
      contains(
        [for k in keys(var.marketplace_image) : lower(k)],
        lower(var.marketplace)
      )
    )
    error_message = "When image_type is 'marketplace', marketplace must match a key in marketplace_image."
  }
}

variable "marketplace_image" {
  description = "Marketplace image details. Required if image_type = marketplace."
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  }))
  default = {
    US = {
      publisher = "dellemc"
      offer     = "apexfilestorage"
      sku       = "apexfilestorage_paidplan"
      version   = "latest"
    }
    International = {
      publisher = "dellemceisi123456"
      offer     = "apexfilestorageeisi"
      sku       = "apexfilestorage_paidplan_eisi"
      version   = "latest"
    }
    Canada = {
      publisher = "dell-canada-inc"
      offer     = "apexfilestoragecanada"
      sku       = "apexfilestorage_paidplan_canada"
      version   = "latest"
    }
  }
}

variable "image_id" {
  description = "Managed image resource ID. Required if image_type = managed_image."
  type        = string
  default     = null
  validation {
    condition     = (lower(var.image_type) != "managed_image" || (var.image_id != null && var.image_id != ""))
    error_message = "When image_type = managed_image, you must provide a valid image_id."
  }
}

variable "post_install_commands" {
  type        = list(string)
  default     = []
  description = "The list of commands to run after the installation."
  nullable    = true
}

variable "internal_prefix" {
  type        = string
  description = "The prefix for the internal subnet."
  validation {
    condition     = var.internal_prefix != null
    error_message = "Please provide a valid prefix for the internal subnet."
  }
  nullable = false
}

variable "external_prefix" {
  type        = string
  description = "The prefix for the external subnet."
  validation {
    condition     = var.external_prefix != null
    error_message = "Please provide a valid prefix for the external subnet."
  }
  nullable = false
}

variable "internal_subnet_id" {
  type        = string
  description = "The value of the subnet ID for the internal subnet."
  validation {
    condition     = var.internal_subnet_id != null
    error_message = "Please provide a valid ID for the internal subnet."
  }
  nullable = false
}

variable "external_subnet_id" {
  type        = string
  description = "The value of the subnet ID for the external subnet."
  validation {
    condition     = var.external_subnet_id != null
    error_message = "Please provide a valid ID for the external subnet."
  }
  nullable = false
}

variable "location" {
  type        = string
  description = "The location for the resource group, internal and external subnet."
  validation {
    condition     = var.location != null
    error_message = "Please provide a location for the resource group, internal and external subnet."
  }
  nullable = false
}

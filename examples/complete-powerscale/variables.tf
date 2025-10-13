/*

        Copyright (c) 2024 Dell Inc. or its subsidiaries. All rights reserved.

*/

variable "cluster_id" {
  default = null
}

variable "resource_group" {
  default = null
}

variable "network_id" {
}

variable "node_size" {
  default = "Standard_D8ds_v4"
}

variable "cluster_name" {
  validation {
    condition     = length(var.cluster_name) <= 40 && can(regex("^[a-zA-Z]+[a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "The supplied cluster name must contain only numbers and letters starting with a letter and less than 41 characters."
  }
}

variable "cluster_nodes" {
  default = 3
  validation {
    condition     = var.cluster_nodes <= 20
    error_message = "PowerScale clusters on Azure must be less then or equal to 20 nodes."
  }
}

variable "update_domain_count" {
  default = 20
}

variable "internal_gateway_address" {
  default = null
}

# The offset into the address ranges where we will begin our IP ranges
variable "addr_range_offset" {
  default = 5
  validation {
    condition     = var.addr_range_offset > 4
    error_message = "Azure reserves the first four IP addresses in subnets. addr_range_offset must be >4."
  }
}

# The max number of nodes we will scale up to
variable "max_num_nodes" {
  default = 20
  validation {
    condition     = var.max_num_nodes <= 20
    error_message = "PowerScale clusters on Azure must be less then or equal to 20 nodes."
  }
}

variable "external_gateway_address" {
  default = null
}

variable "cluster_admin_username" {
  default = "azonefs"
}


variable "default_hashed_password" {
  type        = string
  sensitive   = true
  description = "The default hashed password, using this will set the same hashed password to both root and admin users."
  default     = null
}

variable "hashed_admin_passphrase" {
  type        = string
  sensitive   = true
  description = "The admin user's hashed password for the OneFS cluster."
  default     = null
}

variable "hashed_root_passphrase" {
  type        = string
  sensitive   = true
  description = "The root user's hashed password for the OneFS cluster."
  default     = null
}

variable "image_id" {
}

variable "dns_servers" {
  default = "[ \"168.63.129.16\", \"169.254.169.254\"]"
}

variable "dns_domains" {
  default = "c.daring-sunset-250103.internal"
}

variable "smartconnect_zone" {
  type        = string
  description = "FQDN to use as the DNS zone for SmartConnect"
  default     = ""
}

variable "ocm_endpoint" {
  type        = string
  description = "Endpoint for OneFS cluster to communicate with OCM."
  default     = ""
}

variable "resource_tags" {
  type = map(string)
  default = {
  }
}

variable "os_disk_type" {
  default = "Premium_LRS"
}

variable "data_disk_type" {
  default = "Premium_LRS"
}

variable "data_disk_size" {
  default = 12
}

variable "data_disks_per_node" {
  default = 3
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
}

variable "timezone" {
  type    = string
  default = "Greenwich Mean Time"
}


variable "subscription_id" {
  type = string
}

variable "get_subnets" {
  description = "Value to get the subnets from the resource group"
  type        = string
  default     = "true"
}


variable "external_subnet_name" {
  description = "Name of the external subnet"
  type        = string
}

variable "internal_subnet_name" {
  description = "Name of the internal subnet"
  type        = string
}

variable "internal_nsg_name" {
  description = "Name of internal network security group"
  type        = string
}

variable "internal_nsg_resource_group" {
  description = "Name of internal network security group resource group"
  type        = string
}

variable "external_nsg_name" {
  description = "Name of external network security group"
  type        = string
}

variable "external_nsg_resource_group" {
  description = "Name of external network security group resource group"
  type        = string
}

variable "use_disk_encryption" {
  description = "Set to true to enable disk encryption using an existing disk encryption set"
  type        = bool
}
variable "disk_encryption_set_name" {
  description = "Name of existing disk encryption set"
  type        = string
  default     = null
}
variable "disk_encryption_set_resource_group" {
  description = "Name of disk encryption set resource group"
  type        = string
  default     = null
}

variable "identity_list" {
  description = "List of resource id(s) that reference managed user-assigned identities"
  type        = list(string)
  default     = []
}

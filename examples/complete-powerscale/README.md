# Deploy a PowerScale Cluster in Azure

A Terraform configuration file, `main.tf`, has been provided in this directory as an example module to deploy a PowerScale cluster.

## Description

In this directory, there is a template file called `terraform.tfvars.template`. Use this as the basis to create your own `terraform.tfvars` file.

There are required input variables that have been left blank which will need to be filled in:

```json
{
    cluster_name           = "<cluster_name>"
    hashed_admin_passphrase = "<hashed_admin_passphrase>"
    hashed_root_passphrase  = "<hashed_root_passphrase>"
    image_id               = "<vhd_image_id_with_location>"

    network_id               = "<vnet_including_location>"

    subscription_id = <#######-####-####-####-############>
    resource_group = <resource group name>
    internal_nsg_name = "<internal network security group>"
    internal_nsg_resource_group = "<interal network security resource group>"
    external_nsg_name = "<external network security group>"
    external_nsg_resource_group = "<external network security resource group>"

    internal_subnet_name     = "<name_of_internal_subnet>"
    external_subnet_name     = "<name_of_external_subnet>"

    use_disk_encryption                = <false|true>
    disk_encryption_set_name           = "<name of disk encryption set>"
    disk_encryption_set_resource_group = "<disk encryption set resource group>"
}
```

## Admin and Root User Passwords

On using the `default_hashed_password` input parameter, both the root and admin user will be assigned the same password as provided in `default_hashed_password`.

You can pass separate passwords for the root and admin user using `hashed_root_passphrase` and `hashed_admin_passphrase` respectively.

To get the hashed password you can use openssl-passwd utility.

<details>
<summary>Click to expand steps to generate hashed password</summary>

You can use the following commands to get the hashed password:

```shell
openssl passwd -5 -salt `head -c 8 /dev/random | xxd -p` "<replace-password-here>"
```

In the above command, `head -c 8 /dev/random | xxd -p` is used to generate an 8 byte random string in its hexadecimal representation which is used as the salt for producing the hashed output.
</details>

For the complete set of input variables that can be provided, check the `variables.tf` file.

## Disk Encryption

By enabling disk encryption via setting the `use_disk_encryption` input parameter to true, it is possible to use an existing disk encryption set in azure to encrypt both the OS disks and data disks created by terraform. Note that the name of the existing disk encryption set and the resource group it is located in will need to be added to the `disk_encryption_set_name` and `disk_encryption_set_resource_group` input parameters respectively.

## Connectivity

It is important to limit the connectivity on the internal vnet to only the other virtual nodes in the cluster.

## User-assigned Managed Identity

This is an optional input. By default, the `identity_list` input parameter is left empty. When specified, this allows the user to specify resource id(s) within a list that point to user-assigned identities within Azure.

## Deploy Terraform Module

```shell
terraform init
```

```shell
terraform apply -auto-approve
```

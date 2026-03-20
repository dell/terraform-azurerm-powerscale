# v2.0.0 (2025-11-25)

## Release Summary
The release establishes a standardized process for reviewing, accepting, and documenting external customer feedback/contribution into Terraform scripts used for PowerScale on Azure and minor fixes and enhancements.

## Features

### Data Sources
* Removes `azonefs_resource_group`
* Removes `azonefs_virtual_network`
* Removes `azonefs_internal_subnet`
* Removes `azonefs_external_subnet` 

### Resources
N/A

### Others
* Minimum required terraform version is now 1.9.0.

### Enhancements
* Support VM creation with Marketplace Image.
* Proper Code commenting.
* Clearly marking if variables are mandatory or optional.

### Bug Fixes
* LNN and VM name mismatch issue.

# v1.1.0 (2025-10-28)

## Release Summary
Adds Microsoft Azure customer usage attribution.

When you deploy this template, Microsoft can identify the installation of Dell Technologies software with the deployed Azure resources. Microsoft can correlate these resources used to support the software. Microsoft collects this information to provide the best experiences with their products and to operate their business. The data is collected and governed by Microsoft's privacy policies, located at https://www.microsoft.com/trustcenter.

## Features

### Data Sources

N/A

### Resources

N/A

### Others

N/A

### Enhancements
N/A

# v1.0.1 (2025-10-13)

## Release Summary

The release contains minor fixes and enhancements for the Terraform Module for Dell Technologies (Dell) PowerScale Cluster.

## Features

### Data Sources

N/A

### Resources

N/A

### Others

N/A

### Enhancements

* Adds `post_install_commands` variable to allow for running a list of commands after the installation is complete.

### Bug Fixes

* Fixes a defect where `data_disk_type` variable was not being set properly.
* Fixes a defect where manual network interface configurations may be overwritten when using the original terraform script to add more nodes.

# v1.0.0 (2024-09-02)

## Release Summary

The release supports resources and data sources mentioned in the Features section for Dell Powerscale for Azure.

## Features

### Data Sources

* `azonefs_resource_group` for reading resource group placement of terraform created resources
* `azonefs_virtual_network` for reading virtual network in azure
* `azonefs_internal_subnet` for reading internal subnet in azure
* `azonefs_external_subnet` for reading external subnet in azure
* `azonefs_disk_encryption_set` for reading disk encryption setting from azure


### Resources

* `azonefs_proximity_placement_group` for creating placement group
* `azonefs_aset` for creating availability set
* `azonefs_network_interface_internal` for creating internal network interface
* `azonefs_network_interface_external` for creating external network 
* `azonefs_node` for creating Virtual Machines and associated disks

### Others

N/A

### Enhancements

N/A

### Bug Fixes

N/A

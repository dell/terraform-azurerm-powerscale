<!--

        Copyright (c) 2023 Dell, Inc or its subsidiaries.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.

-->
# PowerScale Cluster Module

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](./docs/CODE_OF_CONDUCT.md)
[![License](https://img.shields.io/badge/License-MPL_2.0-blue.svg)](LICENSE)

The Terraform Module for Dell Technologies (Dell) PowerScale Cluster allows Data Center and IT administrators to use Hashicorp Terraform to automate and orchestrate the provisioning and management of Dell PowerScale Cluster in [Azure](https://azure.microsoft.com/en-us/) using the azurerm (azure resource manager) provider.

## Table of contents

* [Code of Conduct](./docs/CODE_OF_CONDUCT.md)
* [Support](#support)
* [Security](./docs/SECURITY.md)
* [License](#license)
* [Prerequisites](#prerequisites)
* [PowerScale Cluster](#powerscale-cluster)

## Support
For any queries regarding the Terraform Module for Dell PowerScale cluster issues, questions or feedback, please follow our [support process](./docs/SUPPORT.md)

## License
The Terraform Module for Dell PowerScale cluster is released and licensed under the MPL-2.0 license. Once an end-user initiates deployment of terraform-azurerm-powerscale, that end-user will deploy other open-source and/or third-party software that is licensed separately by their respective developer communities and/or third parties. For a comprehensive list of software and their licenses, click [here](./docs/DEPENDENCIES.md). Dell (or any other contributors) shall have no liability regarding (and no responsibility to provide support for) an end-user's use of any open-source and/or third-party software and terraform-azurerm-powerscale users are solely responsible for ensuring that they are complying with all such licenses. terraform-azurerm-powerscale is provided “as is” without any warranty, express or implied. Dell (or any other contributors) shall have no liability for any direct, indirect, incidental, punitive, special, or consequential damages for an end-user’s use of terraform-azurerm-powerscale. See [LICENSE](./LICENSE) for the full terms.

## Prerequisites

| **Terraform Module** | **OneFS OS Version** | **Terraform** |
|----------------------|----------------------|---------------|
| v1.0.0               | >= 9.8.0.0           | >= 1.3.6 <br> |

## PowerScale Cluster

To deploy the PowerScale cluster you can refer to the steps mentioned [here](./docs/POWERSCALE_CLUSTER.md).

**Note:** It is important to limit the connectivity on the internal vnet to only the other virtual nodes in the cluster.

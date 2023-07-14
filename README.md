# terraform-azurerm-nva

This opinionated module deploys a Virtual Machine (NVA) along with its necessary dependencies including Subnets, Network Interfaces, and Public Ips. 

## Features 
- Scale Network Interfaces. 
- Input NVA configuration file. 

## Prerequisites 
- Resource Group.
- Virtual Network. 
## Example 
This example uses a Cisco CSR 1000v for the deployment. 

Start with populating the .txt configuration file for the Cisco CSR in your root directory. 
```txt
# csr_config.txt

ip route 10.0.0.0 255.0.0.0 10.0.2.4 
ip route 172.16.0.0 255.240.0.0 10.0.2.4 
ip route 192.168.0.0 255.255.0.0 10.0.2.4 
!
wr mem

```

Next create the Terraform configuration as follows, remembering to update the module version. 
```hcl 
resource "random_password" "password" {
  length           = 12
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

resource "azurerm_marketplace_agreement" "csr" {
  publisher = "cisco"
  offer     = "cisco-csr-1000v"
  plan      = "16_12-byol"
}

resource "azurerm_resource_group" "csr" {
  location = "northeurope"
  name     = "rg-csr"
}

resource "azurerm_virtual_network" "csr" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.csr.location
  name                = "vnet-hub"
  resource_group_name = azurerm_resource_group.csr.name
}

module "csr" {
  source  = "luke-taylor/nva/azurerm"
  version = "<VERSION>"

  admin_password = "random_password.password.result"
  admin_username = "azureuser"
  image = {
    publisher_id = "cisco"
    product_id   = "cisco-csr-1000v"
    plan_id      = "16_12-byol"
    version      = "latest"
  }
  virtual_machine_name = "vm-csr"
  vm_size              = "Standard_D3_v2"
  resource_group_name  = azurerm_resource_group.csr.name
  virtual_network_name = azurerm_virtual_network.csr.name
  location             = azurerm_resource_group.csr.location
  nva_config_file_path = "${path.root}/csr_config.txt"
  network_interfaces = {
    public = {
      primary_interface          = true
      public_ip_creation_enabled = true
      subnet_config = {
        address_prefixes = ["10.0.1.0/24"]
      }
    }
    private = {
      subnet_config = {
        address_prefixes = ["10.0.2.0/24"]
      }
    }
  }
}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                      | Version       |
|---------------------------------------------------------------------------|---------------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3        |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm)       | >= 3.1, < 4.0 |

## Providers

| Name                                                          | Version       |
|---------------------------------------------------------------|---------------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.1, < 4.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                                       | Type     |
|--------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_linux_virtual_machine.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface)         | resource |
| [azurerm_public_ip.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip)                         | resource |
| [azurerm_subnet.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)                               | resource |

## Inputs

| Name                                                                                                 | Description                                                   | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Default  | Required |
|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password)                       | The admin password for the virtual machine.                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a      |   yes    |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username)                       | The admin username for the virtual machine.                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a      |   yes    |
| <a name="input_identity"></a> [identity](#input\_identity)                                           | values for the identity to use for the virtual machine.       | <pre>object({<br>    type         = string<br>    identity_ids = optional(list(string))<br>  })</pre>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | `null`   |    no    |
| <a name="input_image"></a> [image](#input\_image)                                                    | values for the image to use for the virtual machine.          | <pre>object({<br>    plan_id      = string<br>    publisher_id = string<br>    product_id   = string<br>    version      = optional(string, "latest")<br>  })</pre>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | n/a      |   yes    |
| <a name="input_location"></a> [location](#input\_location)                                           | The location/region of the resources.                         | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a      |   yes    |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces)           | A map of network\_interfaces to create.                       | <pre>map(object({<br>    accelerated_networking_enabled = optional(bool)<br>    name                           = optional(string)<br>    primary_interface              = optional(string, false)<br>    private_ip_address             = optional(string)<br>    private_ip_address_allocation  = optional(string, "Dynamic")<br>    public_ip_creation_enabled     = optional(bool, false)<br>    tags                           = optional(map(string), {})<br>    public_ip_config = optional(object({<br>      name              = optional(string)<br>      allocation_method = optional(string, "Dynamic")<br>      sku               = optional(string)<br>      tags              = optional(map(string), {})<br>    }), {})<br>    subnet_config = object({<br>      name             = optional(string)<br>      address_prefixes = list(string)<br>    })<br>  }))</pre> | `{}`     |    no    |
| <a name="input_nva_config_file_path"></a> [nva\_config\_file\_path](#input\_nva\_config\_file\_path) | The custom data to use for the virtual machine.               | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `""`     |    no    |
| <a name="input_os_disk"></a> [os\_disk](#input\_os\_disk)                                            | The os disk configuration to use for the virtual machine.     | <pre>object({<br>    caching              = optional(string, "ReadOnly")<br>    storage_account_type = optional(string, "Standard_LRS")<br>    name                 = optional(string, null)<br>  })</pre>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `{}`     |    no    |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)      | The name of the resource group.                               | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a      |   yes    |
| <a name="input_tags"></a> [tags](#input\_tags)                                                       | A mapping of tags to assign to the resource.                  | `map(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `{}`     |    no    |
| <a name="input_tracing_tags_enabled"></a> [tracing\_tags\_enabled](#input\_tracing\_tags\_enabled)   | Whether enable tracing tags that generated by BridgeCrew Yor. | `bool`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | `false`  |    no    |
| <a name="input_tracing_tags_prefix"></a> [tracing\_tags\_prefix](#input\_tracing\_tags\_prefix)      | Default prefix for generated tracing tags                     | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `"avm_"` |    no    |
| <a name="input_virtual_machine_name"></a> [virtual\_machine\_name](#input\_virtual\_machine\_name)   | The name of the virtual machine.                              | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a      |   yes    |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name)   | The name of the virtual network.                              | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a      |   yes    |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size)                                            | The size of the virtual machine.                              | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | n/a      |   yes    |

## Outputs

| Name                                                                                         | Description                                                                     |
|----------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| <a name="output_network_interfaces"></a> [network\_interfaces](#output\_network\_interfaces) | value is a map of objects with the following attributes: id, name, private\_ip  |
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips)                         | value is a map of objects with the following attributes: id, name, ip\_address  |
| <a name="output_virtual_machine"></a> [virtual\_machine](#output\_virtual\_machine)          | value is a map of objects with the following attributes: id, name, identity\_id |
<!-- END_TF_DOCS -->

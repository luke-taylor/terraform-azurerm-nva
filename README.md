# terraform-azurerm-nva

This opinionated module deploys a Virtual Machine (NVA) along with its necessary dependencies including Subnets, Network Interfaces, and Public Ips. 

## Features 
- Virtual Machine:
  - Optional deployment of `n` Network Interfaces.
  - Configurable image plan. 
  - NVA configuration file input.
- Public Ip: 
  - Optional deployment of Public Ip on Network Interface. 
- Subnet
  - Creation of Subnet for each Network Interface. 
- Network Security Group 
  - Optional deployment of Network Security Group for each Subnet. 
  - Optional Security Rule allowing SSH Access. 

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

  admin_password = random_password.password.result
  admin_username = "azureuser"
  image = {
    marketplace_image = true
    publisher_id      = azurerm_marketplace_agreement.csr.publisher
    product_id        = azurerm_marketplace_agreement.csr.offer
    plan_id           = azurerm_marketplace_agreement.csr.plan
    version           = "latest"
  }
  name                 = "vm-csr"
  size                 = "Standard_D3_v2"
  resource_group_name  = azurerm_resource_group.csr.name
  virtual_network_name = azurerm_virtual_network.csr.name
  location             = azurerm_resource_group.csr.location
  nva_config_input     = file("${path.root}/csr_config.txt")
  network_interfaces = {
    public = {
      primary_interface          = true
      public_ip_creation_enabled = true
      subnet = {
        address_prefixes = ["10.0.1.0/24"]
      }
    }
    private = {
      subnet = {
        address_prefixes = ["10.0.2.0/24"]
      }
    }
  }
}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.1, < 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.1, < 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_security_group.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_subnet.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.nva](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | The admin password for the virtual machine. | `string` | `""` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The admin username for the virtual machine. | `string` | `"azureuser"` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | values for the identity to use for the virtual machine. | <pre>object({<br>    type         = string<br>    identity_ids = optional(list(string))<br>  })</pre> | `null` | no |
| <a name="input_image"></a> [image](#input\_image) | values for the image to use for the virtual machine. | <pre>object({<br>    marketplace_image = optional(bool, false)<br>    plan_id           = string<br>    product_id        = string<br>    publisher_id      = string<br>    version           = optional(string, "latest")<br>  })</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location/region of the resources. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the virtual machine. | `string` | `"vm-nva"` | no |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces) | A map of network\_interfaces to create.<br><br>- accelerated\_networking\_enabled: (Optional) Is Accelerated Networking enabled for this Network Interface? Defaults to false.<br>- enable\_ip\_forwarding: (Optional) Is IP Forwarding enabled on this Network Interface? Defaults to true.<br>- name: (Optional) The name of the Network Interface. Changing this forces a new resource to be created.<br>- order: (Optional) The order in which this Network Interface is created relative to other Network Interfaces. Takes map order otherwise. Primary Interface is always first.<br>- primary\_interface: (Optional) Is this the primary Network Interface? Must be set to true for the first Network Interface added to a Virtual Machine. Defaults to false.<br>- private\_ip\_address: (Optional) The Private IP Address to assign to the Network Interface. If no value is provided, a dynamic one will be created.<br>- private\_ip\_address\_allocation: (Optional) The allocation method to use for the Private IP Address. Possible values are Static and Dynamic. Defaults to Dynamic.<br>- public\_ip\_creation\_enabled: (Optional) Should a Public IP Address be created for this Network Interface? Defaults to false.<br>- subnet\_id: (Optional) The ID of the Subnet which should be used for this Network Interface. Changing this forces a new resource to be created.<br>- tags: (Optional) A mapping of tags to assign to the resource.<br><br>- public\_ip: (Optional) A public\_ip block as defined below.<br>  - name: (Optional) The name of the Public IP Address. Changing this forces a new resource to be created.<br>  - allocation\_method: (Optional) The allocation method to use for the Public IP Address. Possible values are Static and Dynamic. Defaults to Dynamic.<br>  - sku: (Optional) The SKU of the Public IP Address. Possible values are Basic and Standard. Defaults to Basic.<br>  - tags: (Optional) A mapping of tags to assign to the resource.<br><br>- subnet: (Required) A subnet block as defined below.<br>  - name: (Optional) The name of the Subnet. Changing this forces a new resource to be created.<br>  - address\_prefixes: (Required) A list of address prefixes for the Subnet.<br>  - network\_security\_group\_id: (Optional) The ID of the Network Security Group to associate with the Subnet.<br>  - nsg\_allow\_ssh\_inbound\_enabled: (Optional) Should SSH inbound traffic be allowed through the Network Security Group? Defaults to false.<br>  - nsg\_creation\_enabled: (Optional) Should a Network Security Group be created for this Subnet? Defaults to false.<br>  - nsg\_name: (Optional) The name of the Network Security Group to create for this Subnet. Changing this forces a new resource to be created. | <pre>map(object({<br>    accelerated_networking_enabled = optional(bool)<br>    enable_ip_forwarding           = optional(bool, true)<br>    name                           = optional(string)<br>    order                          = optional(number, null)<br>    primary_interface              = optional(string, false)<br>    private_ip_address             = optional(string)<br>    private_ip_address_allocation  = optional(string, "Dynamic")<br>    public_ip_creation_enabled     = optional(bool, false)<br>    subnet_id                      = optional(string, null)<br>    tags                           = optional(map(string), {})<br>    public_ip = optional(object({<br>      name              = optional(string)<br>      allocation_method = optional(string, "Dynamic")<br>      sku               = optional(string)<br>      tags              = optional(map(string), {})<br>    }), {})<br>    subnet = optional(object({<br>      name                          = optional(string)<br>      address_prefixes              = list(string)<br>      network_security_group_id     = optional(string, null)<br>      nsg_allow_ssh_inbound_enabled = optional(bool, false)<br>      nsg_creation_enabled          = optional(bool, false)<br>      nsg_name                      = optional(string, null)<br>    }), null)<br>  }))</pre> | `{}` | no |
| <a name="input_nva_config_input"></a> [nva\_config\_input](#input\_nva\_config\_input) | The custom data to use for the virtual machine. | `string` | `""` | no |
| <a name="input_os_disk"></a> [os\_disk](#input\_os\_disk) | The os disk configuration to use for the virtual machine. | <pre>object({<br>    caching              = optional(string, "ReadOnly")<br>    storage_account_type = optional(string, "Standard_LRS")<br>    name                 = optional(string, null)<br>  })</pre> | `{}` | no |
| <a name="input_password_authentication_enabled"></a> [password\_authentication\_enabled](#input\_password\_authentication\_enabled) | value for the password\_authentication\_enabled flag for the virtual machine. | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group. | `string` | n/a | yes |
| <a name="input_size"></a> [size](#input\_size) | The size of the virtual machine. | `string` | `"Standard_D3_v2"` | no |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | The public SSH key to use for the virtual machine. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_tracing_tags_enabled"></a> [tracing\_tags\_enabled](#input\_tracing\_tags\_enabled) | Whether enable tracing tags that generated by BridgeCrew Yor. | `bool` | `false` | no |
| <a name="input_tracing_tags_prefix"></a> [tracing\_tags\_prefix](#input\_tracing\_tags\_prefix) | Default prefix for generated tracing tags | `string` | `"avm_"` | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | The name of the virtual network. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_interfaces"></a> [network\_interfaces](#output\_network\_interfaces) | value is a map of objects with the following attributes: id, name, private\_ip\_address |
| <a name="output_network_security_groups"></a> [network\_security\_groups](#output\_network\_security\_groups) | value is a map of objects with the following attributes: id, name |
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | value is a map of objects with the following attributes: id, name, ip\_address |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | value is a map of objects with the following attributes: id, name, address\_prefixes |
| <a name="output_virtual_machine"></a> [virtual\_machine](#output\_virtual\_machine) | value is a map of objects with the following attributes: id, name, identity\_id |
<!-- END_TF_DOCS -->

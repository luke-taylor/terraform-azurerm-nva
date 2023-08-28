variable "image" {
  type = object({
    marketplace_image = optional(bool, false)
    plan_id           = string
    product_id        = string
    publisher_id      = string
    version           = optional(string, "latest")
  })
  description = "values for the image to use for the virtual machine."
}

variable "location" {
  type        = string
  description = "The location/region of the resources."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "virtual_network_name" {
  type        = string
  description = "The name of the virtual network."
}

variable "admin_password" {
  type        = string
  default     = ""
  description = "The admin password for the virtual machine."
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "The admin username for the virtual machine."
  nullable    = false
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default     = null
  description = "values for the identity to use for the virtual machine."
}

variable "name" {
  type        = string
  default     = "vm-nva"
  description = "The name of the virtual machine."
  nullable    = false
}

variable "network_interfaces" {
  type = map(object({
    accelerated_networking_enabled = optional(bool)
    enable_ip_forwarding           = optional(bool, true)
    name                           = optional(string)
    order                          = optional(number, null)
    primary_interface              = optional(string, false)
    private_ip_address             = optional(string)
    private_ip_address_allocation  = optional(string, "Dynamic")
    public_ip_creation_enabled     = optional(bool, false)
    subnet_id                      = optional(string, null)
    tags                           = optional(map(string), {})
    public_ip = optional(object({
      name              = optional(string)
      allocation_method = optional(string, "Dynamic")
      sku               = optional(string)
      tags              = optional(map(string), {})
    }), {})
    subnet = optional(object({
      name                          = optional(string)
      address_prefixes              = list(string)
      network_security_group_id     = optional(string, null)
      nsg_allow_ssh_inbound_enabled = optional(bool, false)
      nsg_creation_enabled          = optional(bool, false)
      nsg_name                      = optional(string, null)
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of network_interfaces to create.

- accelerated_networking_enabled: (Optional) Is Accelerated Networking enabled for this Network Interface? Defaults to false.
- enable_ip_forwarding: (Optional) Is IP Forwarding enabled on this Network Interface? Defaults to true.
- name: (Optional) The name of the Network Interface. Changing this forces a new resource to be created.
- order: (Optional) The order in which this Network Interface is created relative to other Network Interfaces. Takes map order otherwise. Primary Interface is always first.
- primary_interface: (Optional) Is this the primary Network Interface? Must be set to true for the first Network Interface added to a Virtual Machine. Defaults to false.
- private_ip_address: (Optional) The Private IP Address to assign to the Network Interface. If no value is provided, a dynamic one will be created.
- private_ip_address_allocation: (Optional) The allocation method to use for the Private IP Address. Possible values are Static and Dynamic. Defaults to Dynamic.
- public_ip_creation_enabled: (Optional) Should a Public IP Address be created for this Network Interface? Defaults to false.
- subnet_id: (Optional) The ID of the Subnet which should be used for this Network Interface. Changing this forces a new resource to be created.
- tags: (Optional) A mapping of tags to assign to the resource.

- public_ip: (Optional) A public_ip block as defined below.
  - name: (Optional) The name of the Public IP Address. Changing this forces a new resource to be created.
  - allocation_method: (Optional) The allocation method to use for the Public IP Address. Possible values are Static and Dynamic. Defaults to Dynamic.
  - sku: (Optional) The SKU of the Public IP Address. Possible values are Basic and Standard. Defaults to Basic.
  - tags: (Optional) A mapping of tags to assign to the resource.

- subnet: (Required) A subnet block as defined below.
  - name: (Optional) The name of the Subnet. Changing this forces a new resource to be created.
  - address_prefixes: (Required) A list of address prefixes for the Subnet.
  - network_security_group_id: (Optional) The ID of the Network Security Group to associate with the Subnet.
  - nsg_allow_ssh_inbound_enabled: (Optional) Should SSH inbound traffic be allowed through the Network Security Group? Defaults to false.
  - nsg_creation_enabled: (Optional) Should a Network Security Group be created for this Subnet? Defaults to false.
  - nsg_name: (Optional) The name of the Network Security Group to create for this Subnet. Changing this forces a new resource to be created.


DESCRIPTION
  nullable    = false

  validation {
    condition     = length([for k, v in var.network_interfaces : v.primary_interface if v.primary_interface]) == 1
    error_message = "At least one and only one network interface can be marked as primary."
  }
}

variable "nva_config_input" {
  type        = string
  default     = ""
  description = "The custom data to use for the virtual machine."
  nullable    = false
}

variable "os_disk" {
  type = object({
    caching              = optional(string, "ReadOnly")
    storage_account_type = optional(string, "Standard_LRS")
    name                 = optional(string, null)
  })
  default     = {}
  description = "The os disk configuration to use for the virtual machine."
  nullable    = false
}

variable "password_authentication_enabled" {
  type        = bool
  default     = true
  description = "value for the password_authentication_enabled flag for the virtual machine."
  nullable    = false
}

variable "size" {
  type        = string
  default     = "Standard_D3_v2"
  description = "The size of the virtual machine."
  nullable    = false
}

variable "ssh_key" {
  type        = string
  default     = ""
  description = "The public SSH key to use for the virtual machine."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource."
}

# tflint-ignore: terraform_unused_declarations
variable "tracing_tags_enabled" {
  type        = bool
  default     = false
  description = "Whether enable tracing tags that generated by BridgeCrew Yor."
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tracing_tags_prefix" {
  type        = string
  default     = "avm_"
  description = "Default prefix for generated tracing tags"
  nullable    = false
}

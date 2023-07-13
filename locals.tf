locals {
  public_ips = {
    for k, v in var.network_interfaces : k => {
      allocation_method   = v.public_ip_config.allocation_method
      location            = var.location
      name                = coalesce(v.public_ip_config.name, "pip-${k}")
      resource_group_name = var.resource_group_name
      sku                 = v.public_ip_config.sku
      tags                = v.public_ip_config.tags
    }
    if v.public_ip_creation_enabled
  }
}

locals {
  subnets = {
    for k, v in var.network_interfaces : k => {
      name                 = coalesce(v.subnet_config.name, "sn-${k}")
      resource_group_name  = var.resource_group_name
      virtual_network_name = var.virtual_network_name
      address_prefixes     = v.subnet_config.address_prefixes
    }
  }
}

locals {
  network_interfaces = {
    for k, v in var.network_interfaces : k => {
      name                          = coalesce(v.name, "nic-${k}")
      location                      = var.location
      resource_group_name           = var.resource_group_name
      enable_ip_forwarding          = true
      enable_accelerated_networking = v.accelerated_networking_enabled
      public_ip_creation_enabled    = v.public_ip_creation_enabled
      tags                          = v.tags
      ip_configuration = {
        name                          = "ipconfig${k}"
        private_ip_address_allocation = "Dynamic"
        private_ip_address            = v.private_ip_address
      }
    }
  }
  other_network_interface_keys = [
    for k, v in var.network_interfaces : k if !v.primary_interface
  ]
  primary_network_interface_key = element([
    for k, v in var.network_interfaces : k if v.primary_interface
  ], 0)
}

locals {
  custom_data = <<EOF
Content-Type: multipart/mixed; AZURE="==AZURE=="
MIME-Version: 1.0

--==AZURE==
${var.custom_data}
--==AZURE==
EOF
}


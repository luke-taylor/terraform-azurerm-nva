locals {
  public_ips = {
    for k, v in var.network_interfaces : k => {
      allocation_method   = v.public_ip.allocation_method
      location            = var.location
      name                = coalesce(v.public_ip.name, "pip-${lookup(local.network_interfaces[k], "name", k)}")
      resource_group_name = var.resource_group_name
      sku                 = v.public_ip.sku
      tags                = v.public_ip.tags
    }
    if v.public_ip_creation_enabled
  }
}

locals {
  subnets = {
    for k, v in var.network_interfaces : k => {
      name                 = coalesce(v.subnet.name, "sn-${var.name}-${k}")
      resource_group_name  = var.resource_group_name
      virtual_network_name = var.virtual_network_name
      address_prefixes     = v.subnet.address_prefixes
    }
  }
}
locals {
  network_security_groups = {
    for k, v in var.network_interfaces : k => {
      name                          = coalesce(v.subnet.nsg_name, "nsg-${var.virtual_network_name}-${lookup(local.subnets[k], "name", k)}")
      location                      = var.location
      nsg_allow_ssh_inbound_enabled = v.subnet.nsg_allow_ssh_inbound_enabled
      resource_group_name           = var.resource_group_name
      tags                          = var.tags
    }
    if v.subnet.nsg_creation_enabled
  }
}

locals {
  network_security_group_associations = {
    for k, v in var.network_interfaces : k => {
      network_security_group_id = v.subnet.network_security_group_id
    }
    if !v.subnet.nsg_creation_enabled && v.subnet.network_security_group_id != null
  }
}

locals {
  network_interfaces = {
    for k, v in var.network_interfaces : k => {
      name                          = coalesce(v.name, "nic-${var.name}-${k}")
      location                      = var.location
      resource_group_name           = var.resource_group_name
      enable_ip_forwarding          = v.enable_ip_forwarding
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
    for v in local.sort_other_nics_order_keys : local.other_nics_order_keys[v]
  ]
  other_nics_order_keys = {
    for k, v in var.network_interfaces : v.order == null ? index(keys(var.network_interfaces), k) : v.order => k if !v.primary_interface
  }
  primary_network_interface_key = element([
    for k, v in var.network_interfaces : k if v.primary_interface
  ], 0)
  sort_other_nics_order_keys = sort(keys(local.other_nics_order_keys))
}

locals {
  custom_data = <<EOF
Content-Type: multipart/mixed; AZURE="==AZURE=="
MIME-Version: 1.0

--==AZURE==
${var.nva_config_input}
--==AZURE==
EOF
}


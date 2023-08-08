output "network_interfaces" {
  description = "value is a map of objects with the following attributes: id, name, private_ip_address"
  value = {
    for k, v in azurerm_network_interface.nva : k => {
      id                 = v.id
      name               = v.name
      private_ip_address = v.private_ip_address
    }
  }
}

output "network_security_groups" {
  description = "value is a map of objects with the following attributes: id, name"
  value = {
    for k, v in azurerm_network_security_group.nva : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "public_ips" {
  description = "value is a map of objects with the following attributes: id, name, ip_address"
  value = {
    for k, v in azurerm_public_ip.nva : k => {
      id         = v.id
      ip_address = v.ip_address
      name       = v.name
    }
  }
}

output "subnets" {
  description = "value is a map of objects with the following attributes: id, name, address_prefixes"
  value = {
    for k, v in azurerm_subnet.nva : k => {
      id               = v.id
      name             = v.name
      address_prefixes = v.address_prefixes
    }
  }
}

output "virtual_machine" {
  description = "value is a map of objects with the following attributes: id, name, identity_id"
  value = {
    id          = azurerm_linux_virtual_machine.nva.id
    name        = azurerm_linux_virtual_machine.nva.name
    identity_id = try(azurerm_linux_virtual_machine.nva.identity[0].principal_id, null)
  }
}

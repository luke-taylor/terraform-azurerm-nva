resource "azurerm_subnet" "csr" {
  for_each = local.subnets

  name                 = each.value.name
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.virtual_network_name
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_public_ip" "csr" {
  for_each = local.public_ips

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = each.value.allocation_method
  sku                 = each.value.sku
  tags                = each.value.tags
}

resource "azurerm_network_interface" "csr" {
  for_each = local.network_interfaces

  name                 = each.value.name
  location             = each.value.location
  resource_group_name  = each.value.resource_group_name
  enable_ip_forwarding = each.value.enable_ip_forwarding

  ip_configuration {
    name                          = each.value.ip_configuration.name
    subnet_id                     = azurerm_subnet.csr[each.key].id
    private_ip_address_allocation = each.value.ip_configuration.private_ip_address_allocation
    private_ip_address            = each.value.ip_configuration.private_ip_address
    public_ip_address_id          = each.value.public_ip_creation_enabled ? azurerm_public_ip.csr[each.key].id : null
  }
  depends_on = [azurerm_public_ip.csr, azurerm_subnet.csr]
}

resource "azurerm_linux_virtual_machine" "csr" {
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  name                = var.virtual_machine_name
  location            = var.location
  resource_group_name = var.resource_group_name
  network_interface_ids = concat(
    [
      azurerm_network_interface.csr[local.primary_network_interface_key].id
    ],
    [
      for k in local.other_network_interface_keys : azurerm_network_interface.csr[k].id
    ]
  )

  size                            = var.vm_size
  custom_data                     = base64encode(local.custom_data)
  disable_password_authentication = false
  source_image_reference {
    offer     = var.image.product_id
    publisher = var.image.publisher_id
    sku       = var.image.plan_id
    version   = var.image.version
  }
  plan {
    name      = var.image.plan_id
    product   = var.image.product_id
    publisher = var.image.publisher_id
  }
  os_disk {
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
    name                 = var.os_disk.name
  }

  dynamic "identity" {
    for_each = var.identity == null ? [] : ["Identity"]
    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }

  }
  depends_on = [
    azurerm_network_interface.csr,
    azurerm_subnet.csr,
    azurerm_public_ip.csr
  ]
}

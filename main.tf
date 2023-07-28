resource "azurerm_subnet" "nva" {
  for_each = local.subnets

  address_prefixes     = each.value.address_prefixes
  name                 = each.value.name
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.virtual_network_name
}

resource "azurerm_network_security_group" "nva" {
  for_each = local.network_security_groups

  location            = each.value.location
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  tags = merge(each.value.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "81b80e50dacd858794aa847d89aeac4edf019c46"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-26 13:13:10"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-nva"
    avm_yor_name             = "nva"
    avm_yor_trace            = "978b910b-696d-4a1f-af58-feedb3889244"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))

  dynamic "security_rule" {
    for_each = each.value.nsg_allow_ssh_inbound_enabled ? ["AllowSSHInbound"] : []
    content {
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_range     = "22"
      direction                  = "Inbound"
      name                       = "AllowSshInbound"
      priority                   = 1000
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nva" {
  for_each = merge(local.network_security_groups, local.network_security_group_associations)

  network_security_group_id = try(azurerm_network_security_group.nva[each.key].id, each.value.network_security_group_id)
  subnet_id                 = azurerm_subnet.nva[each.key].id

  depends_on = [
    azurerm_subnet.nva,
    azurerm_network_security_group.nva
  ]
}

resource "azurerm_public_ip" "nva" {
  for_each = local.public_ips

  allocation_method   = each.value.allocation_method
  location            = each.value.location
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  sku                 = each.value.sku
  tags = merge(each.value.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "3090f7478f660100b2a0f0a89b523ef56011f8fc"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-12 15:39:02"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-nva"
    avm_yor_name             = "nva"
    avm_yor_trace            = "5a20c2aa-238e-4750-9d7f-c63d7278ea16"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
}

resource "azurerm_network_interface" "nva" {
  for_each = local.network_interfaces

  location             = each.value.location
  name                 = each.value.name
  resource_group_name  = each.value.resource_group_name
  enable_ip_forwarding = each.value.enable_ip_forwarding
  tags = merge(each.value.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "3090f7478f660100b2a0f0a89b523ef56011f8fc"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-12 15:39:02"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-nva"
    avm_yor_name             = "nva"
    avm_yor_trace            = "8e818642-380c-4c47-9454-4160848cd795"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))

  ip_configuration {
    name                          = each.value.ip_configuration.name
    private_ip_address_allocation = each.value.ip_configuration.private_ip_address_allocation
    private_ip_address            = each.value.ip_configuration.private_ip_address
    public_ip_address_id          = each.value.public_ip_creation_enabled ? azurerm_public_ip.nva[each.key].id : null
    subnet_id                     = azurerm_subnet.nva[each.key].id
  }

  depends_on = [azurerm_public_ip.nva, azurerm_subnet.nva]
}

resource "azurerm_linux_virtual_machine" "nva" {
  admin_username = var.admin_username
  location       = var.location
  name           = var.name
  network_interface_ids = concat(
    [
      azurerm_network_interface.nva[local.primary_network_interface_key].id
    ],
    [
      for k in local.other_network_interface_keys : azurerm_network_interface.nva[k].id
    ]
  )
  resource_group_name             = var.resource_group_name
  size                            = var.size
  admin_password                  = var.admin_password
  custom_data                     = base64encode(local.custom_data)
  disable_password_authentication = !var.password_authentication_enabled
  tags = merge(var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "9dd997e6858cc3c9bd814219b77128ec5c79ca81"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-27 09:40:23"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-nva"
    avm_yor_name             = "nva"
    avm_yor_trace            = "2600c47b-44ab-4484-a42a-6c58787ea557"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))

  os_disk {
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
    name                 = var.os_disk.name
  }
  dynamic "admin_ssh_key" {
    for_each = var.ssh_key == "" ? [] : ["AdminSshKey"]
    content {
      public_key = var.ssh_key
      username   = var.admin_username
    }
  }
  dynamic "identity" {
    for_each = var.identity == null ? [] : ["Identity"]
    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }

  }
  plan {
    name      = var.image.plan_id
    product   = var.image.product_id
    publisher = var.image.publisher_id
  }
  source_image_reference {
    offer     = var.image.product_id
    publisher = var.image.publisher_id
    sku       = var.image.plan_id
    version   = var.image.version
  }

  depends_on = [
    azurerm_network_interface.nva,
    azurerm_subnet.nva,
    azurerm_public_ip.nva
  ]
}

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
  offer     = "cisco-csr-1000v"
  plan      = "16_12-byol"
  publisher = "cisco"
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

resource "azurerm_subnet" "csr" {
  address_prefixes     = ["10.0.2.0/24"]
  name                 = "sn-private"
  resource_group_name  = azurerm_resource_group.csr.name
  virtual_network_name = azurerm_virtual_network.csr.name
}

module "csr" {
  source = "../.."

  admin_password = random_password.password.result
  admin_username = "azureuser"
  image = {
    marketplace_image = true
    publisher_id      = azurerm_marketplace_agreement.csr.publisher
    product_id        = azurerm_marketplace_agreement.csr.offer
    plan_id           = azurerm_marketplace_agreement.csr.plan
    version           = "latest"
  }
  name                 = "vm-csr-001"
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
      subnet_id = azurerm_subnet.csr.id
    }
  }
}


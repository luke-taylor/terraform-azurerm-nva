resource "random_password" "password" {
  length           = 12
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

# resource "azurerm_marketplace_agreement" "csr" {
#   publisher = "cisco"
#   offer     = "cisco-csr-1000v"
#   plan      = "16_12-byol"
# }

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
  source = "../.."

  admin_password    = random_password.password.result
  admin_username    = "azureuser"
  marketplace_image = true
  image = {
    publisher_id = "cisco"
    product_id   = "cisco-csr-1000v"
    plan_id      = "16_12-byol"
    version      = "latest"
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


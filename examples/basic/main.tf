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

  admin_password = random_password.password.result
  admin_username = "azureuser"
  image = {
    publisher_id = "cisco"
    product_id   = "cisco-csr-1000v"
    plan_id      = "16_12-byol"
    version      = "latest"
  }
  virtual_machine_name = "csr-003"
  vm_size              = "Standard_D3_v2"
  resource_group_name  = azurerm_resource_group.csr.name
  virtual_network_name = azurerm_virtual_network.csr.name
  location             = azurerm_resource_group.csr.location
  custom_data          = <<EOF
    config t
    router bgp 65003
    bgp log-neighbor-changes
    neighbor 10.0.6.4 remote-as 65515
    neighbor 10.0.6.4 ebgp-multihop 255
    neighbor 10.0.6.4 update-source GigabitEthernet2
    neighbor 10.0.6.5 remote-as 65515
    neighbor 10.0.6.5 ebgp-multihop 255
    neighbor 10.0.6.5 update-source GigabitEthernet2
    !
    ip route 10.0.0.0 255.0.0.0 10.0.14.4 
    ip route 172.16.0.0 255.240.0.0 10.0.14.4 
    ip route 192.168.0.0 255.255.0.0 10.0.14.4 
    !
    wr mem
EOF
  network_interfaces = {
    public = {
      primary_interface          = true
      public_ip_creation_enabled = true
      subnet_config = {
        address_prefixes = ["10.0.13.0/24"]
      }
    }
    private = {
      subnet_config = {
        address_prefixes = ["10.0.14.0/24"]
      }
    }
  }
}


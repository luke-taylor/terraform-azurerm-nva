module "csr" {
  source = "../.."

  admin_password = "Abcdef123456"
  admin_username = "azureuser"
  image = {
    publisher_id = "cisco"
    product_id   = "cisco-csr-1000v"
    plan_id      = "16_12-byol"
    version      = "latest"
  }
  virtual_machine_name = "csr-003"
  vm_size              = "Standard_D3_v2"
  resource_group_name  = "rg-wth"
  virtual_network_name = "hub"
  location             = "northeurope"
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


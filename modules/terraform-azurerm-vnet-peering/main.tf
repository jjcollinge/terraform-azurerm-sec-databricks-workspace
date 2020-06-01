provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "vnet" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "local" {
  name                = var.vnet_local_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
  }

  subnet {
    name           = "subnet3"
    address_prefix = "10.0.3.0/24"
  }

  subnet {
    name           = "subnet4"
    address_prefix = "10.0.4.0/24"
  }

  subnet {
    name           = "subnet5"
    address_prefix = "10.0.5.0/24"
  }
}

resource "azurerm_virtual_network_peering" "sharedToLocal" {
  name                        = "peerSharedToLocal"
  resource_group_name         = var.resource_group_name
  virtual_network_name        = azurerm_virtual_network.local.name
  remote_virtual_network_id   = data.azurerm_virtual_network.shared.id
}


# subnet for: datalake, databricks
# private endpoint for: datalake 
# nsg for databricks and datalake
# asg for everything (?)
# fw rules

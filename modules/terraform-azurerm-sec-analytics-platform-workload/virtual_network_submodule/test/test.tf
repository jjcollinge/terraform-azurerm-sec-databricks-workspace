provider "azurerm" {
  version = "~>2.0"
  features {}
}

# Set up shared vnet and rg for testing purposes only

resource "azurerm_resource_group" "shared" {
  name     = "shared_rg"
  location = "uksouth"
}

resource "azurerm_virtual_network" "shared" {
  name                = "shared_vnet" 
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  address_space       = ["10.1.0.0/16"]
}


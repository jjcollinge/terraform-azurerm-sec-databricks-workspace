provider "azurerm" {
  version = "~>2.0"
  features {}
}

locals {
  unique_name_stub = substr(module.naming.unique-seed, 0, 5)
}

module "naming" {
  source = "git@ssh.dev.azure.com:v3/IDC-Govt/BOUNDARY/terraform-azurerm-naming"
}

resource "azurerm_resource_group" "analytics_platform" {
  name     = "${module.naming.resource_group.slug}-ap-min-test-${local.unique_name_stub}"
  location = "uksouth"
}

resource "azurerm_virtual_network" "example_shared_services" {
  name                = "${module.naming.virtual_network.name_unique}-shared-services-${local.unique_name_stub}"
  resource_group_name = azurerm_resource_group.analytics_platform.name
  location            = azurerm_resource_group.analytics_platform.location
  address_space       = ["10.0.0.0/24"]
}

module "analytics_platform" {
  source                                              = "../../"
  shared_services_virtual_network_resource_group_name = azurerm_resource_group.analytics_platform.name
  shared_services_virtual_network_name                = azurerm_virtual_network.example_shared_services.name
  virtual_network_cidr                                = "11.0.0.0/20"
}

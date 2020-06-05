provider "azurerm" {
  version = "~>2.0"
  features {}
}

locals {
  prefix = var.prefix
  suffix = concat(["ap"], var.suffix)
}

module "naming" {
  source = "https://github.com/Azure/terraform-azurerm-naming.git"
  prefix = local.prefix
  suffix = local.suffix
}

resource "azurerm_resource_group" "analytics_platform" {
  name     = module.naming.resource_group.name
  location = var.analytics_platform_resource_group_location
}

module "virutal_network" {
  source                                              = "./virtual_network_submodule"
  prefix                                              = local.prefix
  suffix                                              = local.suffix
  analytics_platform_resource_group                   = azurerm_resource_group.analytics_platform
  virtual_network_cidr                                = var.virtual_network_cidr
  shared_services_virtual_network_resource_group_name = var.shared_services_virtual_network_resource_group_name
  shared_services_virtual_network_name                = var.shared_services_virtual_network_name
}


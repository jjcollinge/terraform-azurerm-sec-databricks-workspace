provider "azurerm" {
  version = "~>2.0"
  features {}
}

module "naming" {
  source = "https://github.com/Azure/terraform-azurerm-naming.git"
  prefix = var.prefix
  suffix = var.suffix
}

resource "azurerm_virtual_network" "local" {
  name                = module.naming.virtual_network.name
  location            = var.analytics_platform_resource_group.location
  resource_group_name = var.analytics_platform_resource_group.name
  address_space       = [var.virtual_network_cidr]
}

resource "azurerm_subnet" "databricks_public_subnet" {
  name                 = join(module.naming.subnet.dashes ? "-" : "", [module.naming.subnet.name, "databricks-public"])
  resource_group_name  = var.analytics_platform_resource_group.name
  virtual_network_name = azurerm_virtual_network.local.name
  address_prefixes     = [cidrsubnet(var.virtual_network_cidr, 5, 0)]
}

resource "azurerm_subnet" "databricks_private_subnet" {
  name                 = join(module.naming.subnet.dashes ? "-" : "", [module.naming.subnet.name, "databricks-private"])
  resource_group_name  = var.analytics_platform_resource_group.name
  virtual_network_name = azurerm_virtual_network.local.name
  address_prefixes     = [cidrsubnet(var.virtual_network_cidr, 5, 1)]
}

resource "azurerm_subnet" "data_lake_subnet" {
  name                 = join(module.naming.subnet.dashes ? "-" : "", [module.naming.subnet.name, "datalake"])
  resource_group_name  = var.analytics_platform_resource_group.name
  virtual_network_name = azurerm_virtual_network.local.name
  address_prefixes     = [cidrsubnet(var.virtual_network_cidr, 5, 2)]
}

resource "azurerm_subnet" "audit_subnet" {
  name                 = join(module.naming.subnet.dashes ? "-" : "", [module.naming.subnet.name, "audit"])
  resource_group_name  = var.analytics_platform_resource_group.name
  virtual_network_name = azurerm_virtual_network.local.name
  address_prefixes     = [cidrsubnet(var.virtual_network_cidr, 5, 3)]
}

resource "azurerm_subnet" "secrets_subnet" {
  name                 = join(module.naming.subnet.dashes ? "-" : "", [module.naming.subnet.name, "secrets"])
  resource_group_name  = var.analytics_platform_resource_group.name
  virtual_network_name = azurerm_virtual_network.local.name
  address_prefixes     = [cidrsubnet(var.virtual_network_cidr, 5, 4)]
}

resource "azurerm_subnet" "apim_subnet" {
  name                 = join(module.naming.subnet.dashes ? "-" : "", [module.naming.subnet.name, "apim"])
  resource_group_name  = var.analytics_platform_resource_group.name
  virtual_network_name = azurerm_virtual_network.local.name
  address_prefixes     = [cidrsubnet(var.virtual_network_cidr, 5, 5)]
}

resource "azurerm_virtual_network_peering" "ap_to_ss_peering" {
  name                      = "vnp-ap-to-ss"
  resource_group_name       = var.analytics_platform_resource_group.name
  virtual_network_name      = azurerm_virtual_network.local.name
  remote_virtual_network_id = data.azurerm_virtual_network.shared.id
}

# subnet for: datalake, databricks
# private endpoint for: datalake 
# nsg for databricks and datalake
# asg for everything (?)
# fw rules

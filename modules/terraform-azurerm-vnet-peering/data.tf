data "azurerm_virtual_network" "shared" {
  resource_group_name = var.shared_services_rg_name
  name                = var.shared_services_vnet_name
}

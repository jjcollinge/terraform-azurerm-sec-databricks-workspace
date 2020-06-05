data "azurerm_virtual_network" "shared" {
  resource_group_name = var.shared_services_virtual_network_resource_group_name
  name                = var.shared_services_virtual_network_name
}

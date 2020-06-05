output "analytics_platform_vnet" {
  value = azurerm_virtual_network.local
}

output "analytics_platform_to_shared_services_vnet_peering" {
  value = azurerm_virtual_network_peering.ap_to_ss_peering
}

output "databricks_public_subnet" {
  value = azurerm_subnet.databricks_public_subnet
}

output "databricks_private_subnet" {
  value = azurerm_subnet.databricks_private_subnet
}

output "data_lake_subnet" {
  value = azurerm_subnet.data_lake_subnet
}

output "audit_subnet" {
  value = azurerm_subnet.audit_subnet
}

output "secrets_subnet" {
  value = azurerm_subnet.secrets_subnet
}

output "apim_subnet" {
  value = azurerm_subnet.apim_subnet
}


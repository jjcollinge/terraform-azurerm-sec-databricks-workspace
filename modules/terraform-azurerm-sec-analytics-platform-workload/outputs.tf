output "analytics_platform_virtual_network" {
  value = module.virutal_network.analytics_platform_vnet
}

output "analytics_platform_key_vault" {
  value = module.security_package.key_vault
}

output "analytics_platform_log_analytics_workspace" {
  value = module.audit_diagnostics_package.log_analytics_workspace
}

output "analytics_platform_api_management" {
  value = module.apim.api_management
}

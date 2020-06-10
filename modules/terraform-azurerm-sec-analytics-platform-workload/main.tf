provider "azurerm" {
  version = "~>2.0"
  features {}
}

locals {
  suffix = concat(["ap"], var.suffix)
}

module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming"
  suffix = local.suffix
}

resource "azurerm_resource_group" "analytics_platform" {
  name     = module.naming.resource_group.name
  location = var.analytics_platform_resource_group_location
}

module "virutal_network" {
  source                                              = "./virtual_network_submodule"
  suffix                                              = local.suffix
  analytics_platform_resource_group                   = azurerm_resource_group.analytics_platform
  virtual_network_cidr                                = var.virtual_network_cidr
  shared_services_virtual_network_resource_group_name = var.shared_services_virtual_network_resource_group_name
  shared_services_virtual_network_name                = var.shared_services_virtual_network_name
}

module "datalake" {
  source                           = "git::https://github.com/Azure/terraform-azurerm-sec-storage-account"
  resource_group_name              = azurerm_resource_group.analytics_platform.name
  storage_account_name             = module.naming.storage_account.name_unique
  storage_account_tier             = "Standard"
  storage_account_replication_type = "LRS"

  #TODO: Work out what additional if any allowed ip ranges and permitted virtual network subnets there needs to be.
  allowed_ip_ranges                    = []
  permitted_virtual_network_subnet_ids = [module.virutal_network.data_lake_subnet.id, module.virutal_network.apim_subnet.id, module.virutal_network.databricks_private_subnet.id]
  enable_data_lake_filesystem          = true
  data_lake_filesystem_name            = module.naming.data_lake_file_system.name_unique
  bypass_internal_network_rules        = true
}

module "security_package" {
  source                               = "git::https://github.com/Azure/terraform-azurerm-sec-security-package"
  use_existing_resource_group          = false
  resource_group_location              = azurerm_resource_group.analytics_platform.location
  key_vault_private_endpoint_subnet_id = module.virutal_network.secrets_subnet.id

  #Temporarily commenting out to avoid name length issue.
  #suffix                               = local.suffix

  #TODO: Work out what additional if any allowed ip ranges and permitted virtual network subnets there needs to be.
  allowed_ip_ranges                    = []
  permitted_virtual_network_subnet_ids = [module.virutal_network.data_lake_subnet.id, module.virutal_network.apim_subnet.id, module.virutal_network.databricks_private_subnet.id]
  sku_name                             = "standard"
  enabled_for_deployment               = false
  enabled_for_disk_encryption          = true
  enabled_for_template_deployment      = false
}

#TODO: Check for key standard i.e key bit length and preferred crypto algorithm
module "datalake_managed_encryption_key" {
  source              = "git::https://github.com/Azure/terraform-azurerm-sec-storage-managed-encryption-key"
  resource_group_name = module.security_package.resource_group
  storage_account     = module.datalake.storage_account
  key_vault_name      = module.security_package.key_vault.name
  suffix              = local.suffix
}

module "audit_diagnostics_package" {
  source                                     = "git::https://github.com/Azure/terraform-azurerm-sec-audit-diagnostics-package"
  storage_account_private_endpoint_subnet_id = module.virutal_network.audit_subnet.id
  use_existing_resource_group                = false
  resource_group_location                    = azurerm_resource_group.analytics_platform.location
  suffix                                     = local.suffix
  event_hub_namespace_sku                    = "Standard"
  event_hub_namespace_capacity               = "1"
  event_hubs = {
    "eh-ap" = {
      name              = module.naming.event_hub.name
      partition_count   = 1
      message_retention = 1
      authorisation_rules = {
        "ehra-ap" = {
          name   = module.naming.event_hub_authorization_rule.name
          listen = true
          send   = true
          manage = true
        }
      }
    }
  }
  log_analytics_workspace_sku           = "PerGB2018"
  log_analytics_retention_in_days       = var.analytics_platform_log_retention_duration
  automation_account_alternate_location = azurerm_resource_group.analytics_platform.location
  automation_account_sku                = "Basic"
  storage_account_name                  = module.naming.storage_account.name_unique
  storage_account_tier                  = "Standard"
  storage_account_replication_type      = "LRS"

  #TODO: Work out what additional if any allowed ip ranges and permitted virtual network subnets there needs to be.

  allowed_ip_ranges                    = concat([], var.authorised_audit_client_ips)
  permitted_virtual_network_subnet_ids = concat([], var.authorised_subnet_ids)
  bypass_internal_network_rules        = true
}

module "databricks-workspace" {
  source                              = "git::https://github.com/Azure/terraform-azurerm-sec-databricks-workspace"
  resource_group_name                 = azurerm_resource_group.analytics_platform.name
  suffix                              = local.suffix
  databricks_workspace_sku            = "premium"
  log_analytics_resource_group_name   = module.audit_diagnostics_package.resource_group
  log_analytics_name                  = module.audit_diagnostics_package.log_analytics_workspace.name
  storage_account_resource_group_name = azurerm_resource_group.analytics_platform.name
  storage_account_name                = module.datalake.storage_account.name
  module_depends_on                   = ["module.audit_diagnostics_package"]
}

module "apim" {
  source              = "git::https://github.com/Azure/terraform-azurerm-sec-api-management"
  resource_group_name = azurerm_resource_group.analytics_platform.name
  suffix              = local.suffix

  #APIM CoreProperties

  #TODO: Add appropriate publisher details
  apim_publisher_name  = "Analytics Platform"
  apim_publisher_email = "Analytics@Platform.com"
  apim_sku             = "Developer_1"

  #APIM Networking Properties
  apim_virtual_network_type                = "Internal"
  apim_virtual_network_subnet_name         = module.virutal_network.apim_subnet.name
  apim_virtual_network_name                = module.virutal_network.analytics_platform_vnet.name
  apim_virtual_network_resource_group_name = azurerm_resource_group.analytics_platform.name

  #API Properties
  apim_policies_path = "./apim_policies/policies.xml"

  #TODO: Establish and configure to use certificates stored in Key Vault
  certificates = []

  #APIM Authorisation

  #TODO: Establish and configure an authorisation server
  enable_authorization_server                     = false
  apim_authorization_server_name                  = ""
  apim_authorization_server_display_name          = ""
  apim_authorization_server_auth_endpoint         = ""
  apim_authorization_server_token_endpoint        = ""
  apim_authorization_server_client_id             = ""
  apim_authorization_server_registration_endpoint = ""
  apim_authorization_server_grant_types           = []
  apim_bearer_token_sending_methods               = []
  apim_authorization_server_methods               = []
}

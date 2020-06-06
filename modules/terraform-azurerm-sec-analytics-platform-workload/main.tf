provider "azurerm" {
  version = "~>2.0"
  features {}
}

locals {
  prefix = var.prefix
  suffix = concat(["ap"], var.suffix)
}

module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming"
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
  prefix                               = local.prefix
  suffix                               = local.suffix

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
  resource_group_name = azurerm_resource_group.analytics_platform.name
  storage_account     = module.datalake.storage_account
  key_vault_name      = module.security_package.key_vault.name
  prefix              = local.prefix
  suffix              = local.suffix
}

module "audit_diagnostics_package" {
  source                                     = "git::https://github.com/Azure/terraform-azurerm-sec-audit-diagnostics-package"
  storage_account_private_endpoint_subnet_id = module.virutal_network.audit_subnet.id
  use_existing_resource_group                = false
  resource_group_location                    = azurerm_resource_group.analytics_platform.location
  prefix                                     = local.prefix
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



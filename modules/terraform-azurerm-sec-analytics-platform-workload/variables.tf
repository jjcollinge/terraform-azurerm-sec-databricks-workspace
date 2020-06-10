#Required Variables
variable "virtual_network_cidr" {
  type        = string
  description = "A Virtual Network CIDR address for which to use in networking the Analytics Platform.data "
}

variable "shared_services_virtual_network_resource_group_name" {
  type        = string
  description = "The name of the resource group in which the shared services virtual network resides within."
}

variable "shared_services_virtual_network_name" {
  type        = string
  description = "The name of the shared services virtual network."
}

#Optional Variables
variable "suffix" {
  type        = list(string)
  description = "A naming suffix to be used in the creation of unique names for Azure resources."
  default     = []
}

variable "analytics_platform_resource_group_location" {
  type        = string
  description = "The Azure region location of where to deploy the Analytics Platfrom."
  default     = "uksouth"
}

variable "analytics_platform_log_retention_duration" {
  type        = number
  description = "The duration in days to retain any logs created by the Analytics Platform. Note: Deleting the Analytics Platform in its entirety will delete any captured logs. This parameter allows you to control log retention within the lifecycle of the Analytics Platform."
  default     = "30"
}

variable "authorised_audit_client_ips" {
  type        = list(string)
  description = "A list of IP addresses of the clients or endpoints athorised to directly access the Analytics Platforms audit logs."
  default     = []
}

variable "authorised_subnet_ids" {
  type        = list(string)
  description = "A list of Azure Subnet ids of the subnets that are allowed to directly access the Analytics Platforms audit subnet."
  default     = []
}

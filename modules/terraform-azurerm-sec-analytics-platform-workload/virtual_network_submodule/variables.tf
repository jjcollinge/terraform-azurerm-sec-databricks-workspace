#Required Variables
variable "analytics_platform_resource_group" {
  type        = any
  description = "The Analytics Platform object of the parent module."
}

variable "virtual_network_cidr" {
  type        = string
  description = "A Virtual Network CIDR address for which to use in networking the Analytics Platform.data"
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
variable "prefix" {
  type        = list(string)
  description = "A naming prefix to be used in the creation of unique names for Azure resources."
  default     = []
}

variable "suffix" {
  type        = list(string)
  description = "A naming suffix to be used in the creation of unique names for Azure resources."
  default     = []
}

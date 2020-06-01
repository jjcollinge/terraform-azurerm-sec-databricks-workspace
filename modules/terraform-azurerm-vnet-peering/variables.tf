variable "resource_group_name" {
  type    = string
  default = "test"
}

variable "resource_group_location" {
  type    = string
  default = "uksouth"
}

variable "shared_services_rg_name" {
  type    = string
  default = "shared_rg"
}  

variable "shared_services_vnet_name" {
  type    = string
  default = "shared_vnet"
}

variable "vnet_local_name" {
  type    = string
  default = "local_vnet"
}

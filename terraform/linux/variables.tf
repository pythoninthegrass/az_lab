# SOURCE: https://stackoverflow.com/a/76194380/15454191
locals {
  dot_env_file_path  = "../../.env"
  dot_env_regex     = "(?m:^\\s*([^#\\s]\\S*)\\s*=\\s*[\"']?(.*[^\"'\\s])[\"']?\\s*$)"
  dot_env           = { for tuple in regexall(local.dot_env_regex, file(local.dot_env_file_path)) : tuple[0] => sensitive(tuple[1]) }
  sub_id            = local.dot_env["SUBSCRIPTION_ID"]
  client_id         = local.dot_env["CLIENT_ID"]
  client_secret     = local.dot_env["CLIENT_SECRET"]
  tenant_id         = local.dot_env["TENANT_ID"]
}

variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "ubuntu"
}

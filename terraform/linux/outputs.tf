output "key_data" {
  value = azurerm_ssh_public_key.ssh_public_key.public_key
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address
}

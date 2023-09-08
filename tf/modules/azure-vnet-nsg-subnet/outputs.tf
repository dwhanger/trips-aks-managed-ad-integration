# Output variable definitions

output "subnet1" {
  description = "Subnet 1 object (web)"
  value       = azurerm_subnet.subnet1
}

output "subnet2" {
  description = "Subnet 2 object (app)"
  value       = azurerm_subnet.subnet2
}

output "subnet3" {
  description = "Subnet 3 object (db)"
  value       = azurerm_subnet.subnet3
}



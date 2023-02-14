locals {
  intance_ip_count = var.environment == "development" ? 2 : 4
}
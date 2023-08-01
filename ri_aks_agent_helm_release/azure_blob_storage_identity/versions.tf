terraform {
  required_version = "> 0.14, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.64.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.40.0"
    }
  }
}

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = ">= 3.33.0"
    }
    azuread = {
        source  = "hashicorp/azuread"
        version = ">= 2.30.0"
    }
  }
}
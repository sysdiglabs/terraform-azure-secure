terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.43.0"
    }
    sysdig = {
      source  = "sysdiglabs/sysdig"
      version = ">= 1.24.2"
    }
  }
}
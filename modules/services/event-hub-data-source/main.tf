# TODO: Remove this at the end, check configuration possibilities
# Azure provider configuration
provider "azurerm" {
  tenant_id = var.tenant_id
  subscription_id = var.event_hub_subscription_id
  features {}
}

# Org case
data "external" "subscriptions" {
    count = var.is_organizational ? 1 : 0
    program = ["bash", "-c", "echo '{\"subscription_ids\": \"'$(az account list --query \"[?tenantId=='${var.tenant_id}'].id\" -o tsv | tr '\n' ',' | sed 's/,$//')'\"}'"]
}

locals {
    count = var.is_organizational ? 1 : 0
    subscription_ids_to_onboard = var.is_organizational ? split(",", data.external.subscriptions[0].result["subscription_ids"]) : var.subscription_ids
}

data "azurerm_subscription" "diagnostic_settings_subscriptions" {
  count = length(local.subscription_ids_to_onboard)
  subscription_id = local.subscription_ids_to_onboard[count.index]
}

#---------------------------------------------------------------------------------------------
# Create service principal in customer tenant
#---------------------------------------------------------------------------------------------
resource "azuread_service_principal" "sysdig_service_principal" {
  # NOTE: Application ID of the APP
  client_id = var.sysdig_client_id
}

#---------------------------------------------------------------------------------------------
# Create a resource group for Sysdig resources
#---------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "sysdig_resource_group" {
  name     = "sysdig-resource-group"
  location = var.location
}

#---------------------------------------------------------------------------------------------
# Create an Event Hub Namespace for Sysdig
#---------------------------------------------------------------------------------------------
resource "azurerm_eventhub_namespace" "sysdig_event_hub_namespace" {
  name                = "sysdig-event-hub-namespace"
  location            = azurerm_resource_group.sysdig_resource_group.location
  resource_group_name = azurerm_resource_group.sysdig_resource_group.name
  // NOTE: Discuss which should be the default plan for the namespace (Basic, Standard, Premium)
  sku = var.namespace_sku
}

#---------------------------------------------------------------------------------------------
# Create an Event Hub within the Sysdig Namespace
#---------------------------------------------------------------------------------------------
resource "azurerm_eventhub" "sysdig_event_hub" {
  name                = "sysdigeventhub"
  namespace_name      = azurerm_eventhub_namespace.sysdig_event_hub_namespace.name
  resource_group_name = azurerm_resource_group.sysdig_resource_group.name
  partition_count     = var.partition_count
  message_retention   = var.message_retention_days
}

#---------------------------------------------------------------------------------------------
# Create a Consumer Group within the Sysdig Event Hub
#---------------------------------------------------------------------------------------------
# NOTE: Check what exactly this is, do we need it one per subscription? Probably not
resource "azurerm_eventhub_consumer_group" "sysdig_consumer_group" {
  name                = "sysdig"
  namespace_name      = azurerm_eventhub_namespace.sysdig_event_hub_namespace.name
  eventhub_name       = azurerm_eventhub.sysdig_event_hub.name
  resource_group_name = azurerm_resource_group.sysdig_resource_group.name
}

#---------------------------------------------------------------------------------------------
# Create an Authorization Rule for the Sysdig Namespace
#---------------------------------------------------------------------------------------------
resource "azurerm_eventhub_namespace_authorization_rule" "sysdig_rule" {
  name                = "sysdig-send-listen-rule"
  namespace_name      = azurerm_eventhub_namespace.sysdig_event_hub_namespace.name
  resource_group_name = azurerm_resource_group.sysdig_resource_group.name

  listen = true
  send   = true
  manage = false
}

#---------------------------------------------------------------------------------------------
# Assign "Azure Event Hubs Data Receiver" role to Sysdig SP for the Event Hub Namespace
#---------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "sysdig_data_receiver" {
  scope                = azurerm_eventhub_namespace.sysdig_event_hub_namespace.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azuread_service_principal.sysdig_service_principal.object_id
}

#---------------------------------------------------------------------------------------------
# Create diagnostic settings for each subscription of management group
#---------------------------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "sysdig_diagnostic_setting_sub" {
    count = length(data.azurerm_subscription.diagnostic_settings_subscriptions)

    name                       = "sysdig_diagnostic_setting"
    target_resource_id         = data.azurerm_subscription.diagnostic_settings_subscriptions[count.index].id
    eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.sysdig_rule.id
    eventhub_name              = azurerm_eventhub.sysdig_event_hub.name

    enabled_log {
        category = "Administrative"
    }

    enabled_log {
        category = "Security"
    }

    enabled_log {
        category = "ServiceHealth"
    }

    enabled_log {
        category = "Alert"
    }

    enabled_log {
        category = "Recommendation"
    }

    enabled_log {
        category = "Policy"
    }

    enabled_log {
        category = "Autoscale"
    }

    enabled_log {
        category = "ResourceHealth"
    } 
}
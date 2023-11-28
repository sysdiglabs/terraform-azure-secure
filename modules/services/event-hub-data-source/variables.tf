variable "tenant_id" {
  type        = string
  description = "Identifier of the Azure tenant"
}

variable "subscription_id" {
  type        = string
  description = "Identifier of the subscription to be onboarded"
}

variable "sysdig_client_id" {
  type        = string
  description = "Application ID of the enterprise application in the Sysdig tenant"
}

variable "location" {
  type        = string
  description = "Location where Sysdig-related resources will be created"
}

variable "partition_count" {
  description = "The number of partitions in the Event Hub"
  type        = number
  default     = 1
}

variable "troughput_units" {
  description = "The number of throughput units to be allocated to the Event Hub"
  type        = number
  default     = 1
}

variable "auto_inflate_enabled" {
  description = "Whether or not auto-inflate is enabled for the Event Hub"
  type        = bool
  default     = false
}

variable "message_retention_days" {
  description = "Number of days during which messages will be retained in the Event Hub"
  type        = number
  default     = 1
}

variable "namespace_sku" {
  type        = string
  description = "SKU (Plan) for the namespace that will be created"
  default     = "Standard"
}


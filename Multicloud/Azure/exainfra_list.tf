# Fetch subscription details
data "azapi_resource" "subscription" {
  type                   = "Microsoft.Resources/subscriptions@2020-06-01"
  response_export_values = ["*"]
}

# List all Oracle Exadata infrastructures for the subscription
data "azapi_resource_list" "list_cloud_exadata_infrastructures_by_subscription" {
  type      = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id = data.azapi_resource.subscription.id
}

# Fetch details of an existing resource group
data "azurerm_resource_group" "example" {
  name = var.resource_group_name
}

# List Oracle Exadata infrastructures within a specific resource group
data "azapi_resource_list" "list_cloud_exadata_infrastructures_by_resource_group" {
  type      = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id = data.azurerm_resource_group.example.id
}

# Variable for resource group name
variable "resource_group_name" {
  description = "The name of the existing Azure resource group to query"
  type        = string
}

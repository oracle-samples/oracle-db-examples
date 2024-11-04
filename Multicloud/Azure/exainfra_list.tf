data "azapi_resource" "subscription" {
  type                   = "Microsoft.Resources/subscriptions@2020-06-01"
  response_export_values = ["*"]
}

// OperationId: CloudExadataInfrastructures_ListBySubscription
// GET /subscriptions/{subscriptionId}/providers/Oracle.Database/cloudExadataInfrastructures
data "azapi_resource_list" "listCloudExadataInfrastructuresBySubscription" {
  type       = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id  = data.azapi_resource.subscription.id
}

data "azurerm_resource_group" "example" {
  name = "existing"
}

// OperationId: CloudExadataInfrastructures_ListByResourceGroup
// GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudExadataInfrastructures
data "azapi_resource_list" "listCloudExadataInfrastructuresByResourceGroup" {
  type       = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id  = azurerm_resource_group.example.id
}

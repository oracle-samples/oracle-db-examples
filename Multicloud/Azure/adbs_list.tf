// OperationId: AutonomousDatabases_ListBySubscription
// GET /subscriptions/{subscriptionId}/providers/Oracle.Database/autonomousDatabases
data "azapi_resource_list" "listAutonomousDatabasesBySubscription" {
  type       = "Oracle.Database/autonomousDatabases@2023-09-01-preview"
  parent_id  = data.azapi_resource.subscription.id
  depends_on = [azapi_resource.autonomousDatabase]
}

// OperationId: AutonomousDatabases_ListByResourceGroup
// GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/autonomousDatabases
data "azapi_resource_list" "listAutonomousDatabasesByResourceGroup" {
  type       = "Oracle.Database/autonomousDatabases@2023-09-01-preview"
  parent_id  = azapi_resource.resourceGroup.id
  depends_on = [azapi_resource.autonomousDatabase]
}

 // List Autonomous Databases by Subscription
data "azapi_resource_list" "listAutonomousDatabasesBySubscription" {
  type       = "Oracle.Database/autonomousDatabases@2023-09-01-preview"
  parent_id  = "/subscriptions/${data.azapi_resource.subscription.id}" // Fixed reference to subscription ID
  depends_on = [azapi_resource.autonomousDbDeploy] // Adjusted to the actual dependent resource
}

// List Autonomous Databases by Resource Group
data "azapi_resource_list" "listAutonomousDatabasesByResourceGroup" {
  type       = "Oracle.Database/autonomousDatabases@2023-09-01-preview"
  parent_id  = azapi_resource.resource_group.id // Reference to the resource group ID
  depends_on = [azapi_resource.autonomousDbDeploy] // Adjusted to the actual dependent resource
}


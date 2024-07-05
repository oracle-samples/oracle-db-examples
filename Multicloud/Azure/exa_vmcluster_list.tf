data "azapi_resource" "subscription" {
  type                   = "Microsoft.Resources/subscriptions@2020-06-01"
  response_export_values = ["*"]
}

// OperationId: CloudExadataInfrastructures_ListBySubscription
// GET /subscriptions/{subscriptionId}/providers/Oracle.Database/cloudExadataInfrastructures
data "azapi_resource_list" "listCloudExadataInfrastructuresBySubscription" {
  type       = "Oracle.Database/cloudVmClusters@2023-09-01-preview"
  parent_id  = data.azapi_resource.subscription.id
}

// List Oracle Exadata VM Clusters by Resource Group

data "azurerm_resource_group" "example" {
  name = "existing"
}

// OperationId: CloudExadataInfrastructures_ListByResourceGroup
// GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudExadataInfrastructures
data "azapi_resource_list" "listCloudExadataInfrastructuresByResourceGroup" {
  type       = "Oracle.Database/cloudVmClusters@2023-09-01-preview"
  parent_id  = azurerm_resource_group.example.id
}

// List Database Nodes on an Oracle Exadata VM Cluster

// OperationId: DbNodes_Get
// GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudVmClusters/{cloudvmclustername}/dbNodes/{dbnodeocid}
data "azapi_resource" "dbNode" {
  type      = "Oracle.Database/cloudVmClusters/dbNodes@2023-09-01-preview"
  parent_id = azapi_resource.cloudVmCluster.id. // VM Cluster Id
  name      = var.resource_name
}

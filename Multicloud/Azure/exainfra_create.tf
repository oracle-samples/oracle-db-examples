resource "azapi_resource" "resource_group" {
  type     = "Microsoft.Resources/resourceGroups@2023-07-01"
  name     = "ExampleRG"
  location = "eastus"
}

// OperationId: CloudExadataInfrastructures_CreateOrUpdate, CloudExadataInfrastructures_Get, CloudExadataInfrastructures_Delete
// PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudExadataInfrastructures/{cloudexadatainfrastructurename}
resource "azapi_resource" "cloudExadataInfrastructure" {
  type      = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id = azapi_resource.resource_group.id
  name      = "ExampleName"
  body = jsonencode({
    "location" : "eastus",
    "zones" : [
      "2"
    ],
    "tags" : {
      "createdby" : "ExampleName"
    },
    "properties" : {
      "computeCount" : 2,
      "displayName" : "ExampleName",
      "maintenanceWindow" : {
        "leadTimeInWeeks" : 0,
        "preference" : "NoPreference",
        "patchingMode" : "Rolling"
      },
      "shape" : "Exadata.X9M",
      "storageCount" : 3
    }
  })
  schema_validation_enabled = false
}

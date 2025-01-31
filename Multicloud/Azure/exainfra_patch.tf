data "azapi_resource" "subscription" {
  type                   = "Microsoft.Resources/subscriptions@2020-06-01"
  response_export_values = ["*"]
}

// OperationId: CloudExadataInfrastructures_Update
// PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudExadataInfrastructures/{cloudexadatainfrastructurename}
resource "azapi_resource_action" "patch_cloudExadataInfrastructure" {
  type        = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  resource_id = azapi_resource.cloudExadataInfrastructure.id
  action      = ""
  method      = "PATCH"
  body = jsonencode({
    "tags" : {
      "updatedby" : "ExampleName"
    }
  })
}

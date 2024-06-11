resource "azapi_resource_action" "stopVMCluster" {
  type        = "Oracle.Database/cloudVmClusters/dbNodes@2023-09-01-preview"
  resource_id = "RESOURCE_ID_HERE"
  action      = "action"
  body = jsonencode({
    "action" : "Stop"
  })
  response_export_values = ["*"]
}

resource "azapi_resource_action" "stopVMCluster" {
  type        = "Oracle.Database/cloudVmClusters/dbNodes@2023-09-01-preview"
  resource_id = "RESOURCE_ID_HERE"
  action      = "action"
  body = jsonencode({
    "action" : "Start"
  })
  response_export_values = ["*"]
}

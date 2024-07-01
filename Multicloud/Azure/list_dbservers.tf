// OperationId: DbServers_Get
// GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudExadataInfrastructures/{cloudexadatainfrastructurename}/dbServers/{dbserverocid}
data "azapi_resource" "dbServer" {
  type      = "Oracle.Database/cloudExadataInfrastructures/dbServers@2023-09-01-preview"
  parent_id = azapi_resource.cloudExadataInfrastructure.id
  name      = var.resource_name
}

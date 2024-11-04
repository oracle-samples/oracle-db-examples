// List an Oracle Exadata Database Shape

data "azapi_resource_id" "location" {
  type      = "Oracle.Database/locations@2023-12-12"
  parent_id = data.azapi_resource.subscription.id
  name      = "eastus"
}

// OperationId: DbSystemShapes_Get
// GET /subscriptions/{subscriptionId}/providers/Oracle.Database/locations/{location}/dbSystemShapes/{dbsystemshapename}
data "azapi_resource" "dbSystemShape" {
  type      = "Oracle.Database/locations/dbSystemShapes@2023-09-01-preview"
  parent_id = data.azapi_resource_id.location.id
  name      = var.resource_name
}

// List Oracle Exadata Database Shapes by Location

// OperationId: DbSystemShapes_ListByLocation
// GET /subscriptions/{subscriptionId}/providers/Oracle.Database/locations/{location}/dbSystemShapes
data "azapi_resource_list" "listDbSystemShapesByLocation" {
  type       = "Oracle.Database/locations/dbSystemShapes@2023-09-01-preview"
  parent_id  = data.azapi_resource_id.location.id
}

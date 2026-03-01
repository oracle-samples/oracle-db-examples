// Fetch location ID for Oracle Exadata shapes
data "azapi_resource_id" "location" {
  type      = "Microsoft.Resources/subscriptions@2023-12-12" // Correcting the parent type
  parent_id = "/subscriptions/${data.azapi_resource.subscription.id}" // Subscription reference
  name      = "eastus" // Location name
}

// Get a specific Oracle Exadata Database Shape
data "azapi_resource" "dbSystemShape" {
  type      = "Oracle.Database/locations/dbSystemShapes@2023-09-01-preview"
  parent_id = data.azapi_resource_id.location.id // Reference to location ID
  name      = var.resource_name // Variable for specific resource name
  depends_on = [data.azapi_resource_id.location] // Ensuring proper dependency
}

// List all Oracle Exadata Database Shapes by Location
data "azapi_resource_list" "listDbSystemShapesByLocation" {
  type       = "Oracle.Database/locations/dbSystemShapes@2023-09-01-preview"
  parent_id  = data.azapi_resource_id.location.id // Reference to location ID
  depends_on = [data.azapi_resource_id.location] // Ensuring proper dependency
}


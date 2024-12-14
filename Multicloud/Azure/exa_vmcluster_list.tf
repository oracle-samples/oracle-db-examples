 # Get subscription details
data "azapi_resource" "subscription" {
  type                   = "Microsoft.Resources/subscriptions@2020-06-01"
  response_export_values = ["*"]
}

# List all Oracle Exadata infrastructures under a subscription
data "azapi_resource_list" "list_cloud_exadata_infrastructures_by_subscription" {
  type      = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id = data.azapi_resource.subscription.id
}

# Get existing resource group details
data "azurerm_resource_group" "existing" {
  name = "existing-resource-group"
}

# List all Oracle Exadata infrastructures in a specific resource group
data "azapi_resource_list" "list_cloud_exadata_infrastructures_by_resource_group" {
  type      = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id = data.azurerm_resource_group.existing.id
}

# Get Database Node information from a specific VM cluster
data "azapi_resource" "db_node" {
  type      = "Oracle.Database/cloudVmClusters/dbNodes@2023-09-01-preview"
  parent_id = var.vm_cluster_id # Pass the VM Cluster ID dynamically
  name      = var.db_node_name  # Pass the database node name dynamically
}

# Variables for VM Cluster ID and Database Node Name
variable "vm_cluster_id" {
  description = "The resource ID of the Oracle Exadata VM Cluster"
}

variable "db_node_name" {
  description = "The name of the specific database node within the VM Cluster"
}

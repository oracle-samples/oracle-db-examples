// OperationId: VirtualNetworkAddresses_CreateOrUpdate, VirtualNetworkAddresses_Get, VirtualNetworkAddresses_Delete
// PUT GET DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudVmClusters/{cloudvmclustername}/virtualNetworkAddresses/{virtualnetworkaddressname}
resource "azapi_resource" "virtualNetworkAddress" {
  type                      = "Oracle.Database/cloudVmClusters/virtualNetworkAddresses@2023-09-01-preview"
  parent_id                 = azapi_resource.cloudVmCluster.id
  name                      = var.resource_name
  body = jsonencode({
    "properties": {
        "ipAddress": "192.168.0.1",
        "vmOcid": "ocid1..aaaa"
      }
  })
  schema_validation_enabled = false
}

// OperationId: VirtualNetworkAddresses_ListByCloudVmCluster
// GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudVmClusters/{cloudvmclustername}/virtualNetworkAddresses
data "azapi_resource_list" "listVirtualNetworkAddressesByCloudVmCluster" {
  type       = "Oracle.Database/cloudVmClusters/virtualNetworkAddresses@2023-09-01-preview"
  parent_id  = azapi_resource.cloudVmCluster.id
}

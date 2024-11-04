resource "azapi_resource" "resource_group" {
  type     = "Microsoft.Resources/resourceGroups@2023-07-01"
  name     = "ExampleRG"  location = "eastus"
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

//-------------VMCluster resources ------------
// OperationId: CloudVmClusters_CreateOrUpdate, CloudVmClusters_Get, CloudVmClusters_Delete
// PUT GET DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudVmClusters/{cloudvmclustername}
resource "azapi_resource" "cloudVmCluster" {
  type                      = "Oracle.Database/cloudVmClusters@2023-09-01-preview"
  parent_id                 = azapi_resource.resourceGroup.id
  name                      = local.exa_cluster_name
  schema_validation_enabled = false
  depends_on                = [azapi_resource.cloudExadataInfrastructure]
  body                      = jsonencode({
    "properties": {
        "dataStorageSizeInTbs": 1000,
        "dbNodeStorageSizeInGbs": 1000,
        "memorySizeInGbs": 1000,
        "timeZone": "UTC",
        "hostname": "hostname1",
        "domain": "domain1",
        "cpuCoreCount": 2,
        "ocpuCount": 3,
        "clusterName": "cluster1",
        "dataStoragePercentage": 100,
        "isLocalBackupEnabled": false,
        "cloudExadataInfrastructureId": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg000/providers/Oracle.Database/cloudExadataInfrastructures/infra1",
        "isSparseDiskgroupEnabled": false,
        "sshPublicKeys": [
          "ssh-key 1"
        ],
        "nsgCidrs": [
          {
            "source": "10.0.0.0/16",
            "destinationPortRange": {
              "min": 1520,
              "max": 1522
            }
          },
          {
            "source": "10.10.0.0/24"
          }
        ],
        "licenseModel": "LicenseIncluded",
        "scanListenerPortTcp": 1050,
        "scanListenerPortTcpSsl": 1025,
        "vnetId": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg000/providers/Microsoft.Network/virtualNetworks/vnet1",
        "giVersion": "19.0.0.0",
        "subnetId": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg000/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/subnet1",
        "backupSubnetCidr": "172.17.5.0/24",
        "dataCollectionOptions": {
          "isDiagnosticsEventsEnabled": false,
          "isHealthMonitoringEnabled": false,
          "isIncidentLogsEnabled": false
        },
        "displayName": "cluster 1",
        "dbServers": [
          "ocid1..aaaa"
        ]
      },
      "location": "eastus"
    }
})
  response_export_values = ["properties.ocid"]
}

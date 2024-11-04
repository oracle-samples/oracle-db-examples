terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    oci = {
      source = "oracle/oci"
    }
  }
}

provider "azapi" {
  skip_provider_registration = false
}

provider "oci" {
  user_ocid        = <user_ocid>
  fingerprint      = <user_fingerprint>
  tenancy_ocid     = <oci_tenancy_ocid>
  region           = "us-ashburn-1"
  private_key_path = <Path to API Key>
}

locals {
  resource_group_name = "TestResourceGroup"
  user                = "Username"
  location            = "eastus"
}

resource "azapi_resource" "resource_group" {
  type     = "Microsoft.Resources/resourceGroups@2023-07-01"
  name     = local.resource_group_name
  location = local.location
}

resource "azapi_resource" "virtual_network" {
  type      = "Microsoft.Network/virtualNetworks@2023-04-01"
  name      = "${local.resource_group_name}_vnet"
  location  = local.location
  parent_id = azapi_resource.resource_group.id
  body = jsonencode({
    properties = {
      addressSpace = {
        addressPrefixes = [
          "10.0.0.0/16"
        ]
      }
      subnets = [
        {
          name = "delegated"
          properties = {
            addressPrefix = "10.0.1.0/24"
            delegations = [
              {
                name = "Oracle.Database.networkAttachments"
                properties = {
                  serviceName = "Oracle.Database/networkAttachments"
                }
              }
            ]
          }
        }
      ]
    }
  })
}

data "azapi_resource_list" "listVirtualNetwork" {
  type                   = "Microsoft.Network/virtualNetworks/subnets@2023-09-01"
  parent_id              = azapi_resource.virtual_network.id
  depends_on             = [azapi_resource.virtual_network]
  response_export_values = ["*"]
}

resource "tls_private_key" "generated_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2023-09-01"
  name      = "${local.resource_group_name}_key"
  location  = local.location
  parent_id = azapi_resource.resource_group.id
  body = jsonencode({
    properties = {
      publicKey = "${tls_private_key.generated_ssh_key.public_key_openssh}"
    }
  })
}

// OperationId: CloudExadataInfrastructures_CreateOrUpdate, CloudExadataInfrastructures_Get, CloudExadataInfrastructures_Delete
// PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudExadataInfrastructures/{cloudexadatainfrastructurename}
resource "azapi_resource" "cloudExadataInfrastructure" {
  type      = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id = azapi_resource.resource_group.id
  name      = "OFake_terraform_deploy_infra_${local.resource_group_name}"
  timeouts {
    create = "1h30m"
    delete = "20m"
  }
  body = jsonencode({
    "location" : "${local.location}",
    "zones" : [
      "2"
    ],
    "tags" : {
      "createdby" : "${local.user}"
    },
    "properties" : {
      "computeCount" : 2,
      "displayName" : "OFake_terraform_deploy_infra_${local.resource_group_name}",
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

// OperationId: DbServers_ListByCloudExadataInfrastructure
// GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudExadataInfrastructures/{cloudexadatainfrastructurename}/dbServers
data "azapi_resource_list" "listDbServersByCloudExadataInfrastructure" {
  type                   = "Oracle.Database/cloudExadataInfrastructures/dbServers@2023-09-01-preview"
  parent_id              = azapi_resource.cloudExadataInfrastructure.id
  depends_on             = [azapi_resource.cloudExadataInfrastructure]
  response_export_values = ["*"]
}

// OperationId: CloudVmClusters_CreateOrUpdate, CloudVmClusters_Get, CloudVmClusters_Delete
// PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Oracle.Database/cloudVmClusters/{cloudvmclustername}
resource "azapi_resource" "cloudVmCluster" {
  type                      = "Oracle.Database/cloudVmClusters@2023-09-01-preview"
  parent_id                 = azapi_resource.resource_group.id
  name                      = "OFake_terraform_deploy_cluster_${local.resource_group_name}"
  schema_validation_enabled = false
  depends_on                = [azapi_resource.cloudExadataInfrastructure]
  timeouts {
    create = "1h30m"
    delete = "20m"
  }
  body = jsonencode({
    "location" : "${local.location}",
    "tags" : {
      "createdby" : "${local.user}"
    },
    "properties" : {
      "subnetId" : "${jsondecode(data.azapi_resource_list.listVirtualNetwork.output).value[0].id}"
      "cloudExadataInfrastructureId" : "${azapi_resource.cloudExadataInfrastructure.id}"
      "cpuCoreCount" : 4
      "dataCollectionOptions" : {
        "isDiagnosticsEventsEnabled" : true,
        "isHealthMonitoringEnabled" : true,
        "isIncidentLogsEnabled" : true
      },
      "dataStoragePercentage" : 80,
      "dataStorageSizeInTbs" : 2,
      "dbNodeStorageSizeInGbs" : 120,
      "dbServers" : [
        "${jsondecode(data.azapi_resource_list.listDbServersByCloudExadataInfrastructure.output).value[0].properties.ocid}",
        "${jsondecode(data.azapi_resource_list.listDbServersByCloudExadataInfrastructure.output).value[1].properties.ocid}"
      ]
      "displayName" : "OFake_terraform_deploy_cluster_${local.resource_group_name}",
      "giVersion" : "19.0.0.0",
      "hostname" : "${local.user}",
      "isLocalBackupEnabled" : false,
      "isSparseDiskgroupEnabled" : false,
      "licenseModel" : "LicenseIncluded",
      "memorySizeInGbs" : 60,
      "sshPublicKeys" : ["${tls_private_key.generated_ssh_key.public_key_openssh}"],
      "timeZone" : "UTC",
      "vnetId" : "${azapi_resource.virtual_network.id}",
      "provisioningState" : "Succeeded"
    }
  })
  response_export_values = ["properties.ocid"]
}

resource "oci_database_db_home" "exa_db_home" {
  source        = "VM_CLUSTER_NEW"
  vm_cluster_id = jsondecode(azapi_resource.cloudVmCluster.output).properties.ocid
  db_version    = "19.20.0.0"
  display_name  = "TFDBHOME"

  database {
    db_name        = "TFCDB"
    pdb_name       = "TFPDB"
    admin_password = "TestPass#2024#"
    db_workload    = "OLTP"
  }
  depends_on = [azapi_resource.cloudVmCluster]
}

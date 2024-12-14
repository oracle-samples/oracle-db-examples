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
  user_ocid        = var.user_ocid
  fingerprint      = var.user_fingerprint
  tenancy_ocid     = var.oci_tenancy_ocid
  region           = var.oci_region
  private_key_path = var.private_key_path
}

locals {
  resource_group_name = var.resource_group_name
  user                = var.user
  location            = var.location
}

# Azure Resource Group
resource "azapi_resource" "resource_group" {
  type     = "Microsoft.Resources/resourceGroups@2023-07-01"
  name     = local.resource_group_name
  location = local.location
}

# Virtual Network with Delegation
resource "azapi_resource" "virtual_network" {
  type      = "Microsoft.Network/virtualNetworks@2023-04-01"
  name      = "${local.resource_group_name}_vnet"
  location  = local.location
  parent_id = azapi_resource.resource_group.id
  body = jsonencode({
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
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

# List Virtual Networks
data "azapi_resource_list" "list_virtual_network" {
  type                   = "Microsoft.Network/virtualNetworks/subnets@2023-09-01"
  parent_id              = azapi_resource.virtual_network.id
  depends_on             = [azapi_resource.virtual_network]
  response_export_values = ["*"]
}

# Generate SSH Key
resource "tls_private_key" "generated_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# SSH Public Key
resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2023-09-01"
  name      = "${local.resource_group_name}_key"
  location  = local.location
  parent_id = azapi_resource.resource_group.id
  body = jsonencode({
    properties = {
      publicKey = tls_private_key.generated_ssh_key.public_key_openssh
    }
  })
}

# Cloud Exadata Infrastructure
resource "azapi_resource" "cloud_exadata_infrastructure" {
  type      = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id = azapi_resource.resource_group.id
  name      = "OFake_terraform_deploy_infra_${local.resource_group_name}"
  timeouts {
    create = "1h30m"
    delete = "20m"
  }
  body = jsonencode({
    location : local.location,
    zones : ["2"],
    tags : {
      createdby : local.user
    },
    properties : {
      computeCount : 2,
      displayName : "OFake_terraform_deploy_infra_${local.resource_group_name}",
      maintenanceWindow : {
        leadTimeInWeeks : 0,
        preference : "NoPreference",
        patchingMode : "Rolling"
      },
      shape : "Exadata.X9M",
      storageCount : 3
    }
  })
  schema_validation_enabled = false
}

# List DB Servers
data "azapi_resource_list" "list_db_servers" {
  type                   = "Oracle.Database/cloudExadataInfrastructures/dbServers@2023-09-01-preview"
  parent_id              = azapi_resource.cloud_exadata_infrastructure.id
  depends_on             = [azapi_resource.cloud_exadata_infrastructure]
  response_export_values = ["*"]
}

# Cloud VM Cluster
resource "azapi_resource" "cloud_vm_cluster" {
  type                      = "Oracle.Database/cloudVmClusters@2023-09-01-preview"
  parent_id                 = azapi_resource.resource_group.id
  name                      = "OFake_terraform_deploy_cluster_${local.resource_group_name}"
  schema_validation_enabled = false
  depends_on                = [azapi_resource.cloud_exadata_infrastructure]
  timeouts {
    create = "1h30m"
    delete = "20m"
  }
  body = jsonencode({
    location : local.location,
    tags : {
      createdby : local.user
    },
    properties : {
      subnetId : jsondecode(data.azapi_resource_list.list_virtual_network.output).value[0].id,
      cloudExadataInfrastructureId : azapi_resource.cloud_exadata_infrastructure.id,
      cpuCoreCount : 4,
      dataCollectionOptions : {
        isDiagnosticsEventsEnabled : true,
        isHealthMonitoringEnabled : true,
        isIncidentLogsEnabled : true
      },
      dataStoragePercentage : 80,
      dataStorageSizeInTbs : 2,
      dbNodeStorageSizeInGbs : 120,
      dbServers : [
        jsondecode(data.azapi_resource_list.list_db_servers.output).value[0].properties.ocid,
        jsondecode(data.azapi_resource_list.list_db_servers.output).value[1].properties.ocid
      ],
      displayName : "OFake_terraform_deploy_cluster_${local.resource_group_name}",
      giVersion : "19.0.0.0",
      hostname : local.user,
      isLocalBackupEnabled : false,
      isSparseDiskgroupEnabled : false,
      licenseModel : "LicenseIncluded",
      memorySizeInGbs : 60,
      sshPublicKeys : [tls_private_key.generated_ssh_key.public_key_openssh],
      timeZone : "UTC",
      vnetId : azapi_resource.virtual_network.id
    }
  })
}

# Exadata DB Home
resource "oci_database_db_home" "exa_db_home" {
  source        = "VM_CLUSTER_NEW"
  vm_cluster_id = jsondecode(azapi_resource.cloud_vm_cluster.output).properties.ocid
  db_version    = "19.20.0.0"
  display_name  = "TFDBHOME"

  database {
    db_name        = "TFCDB"
    pdb_name       = "TFPDB"
    admin_password = var.admin_password
    db_workload    = "OLTP"
  }
  depends_on = [azapi_resource.cloud_vm_cluster]
}

# Outputs for Debugging
output "resource_group_id" {
  value = azapi_resource.resource_group.id
}

output "cloud_vm_cluster_id" {
  value = azapi_resource.cloud_vm_cluster.id
}

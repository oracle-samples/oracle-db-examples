 variable "resource_group_name" {
  description = "Name of the Resource Group"
  default     = "ExampleRG"
}

variable "location" {
  description = "Location for the resources"
  default     = "eastus"
}

variable "exa_cluster_name" {
  description = "Name of the Exadata Cluster"
  default     = "ExampleName"
}

variable "ssh_public_key" {
  description = "SSH Public Key for the VM Cluster"
  default     = "ssh-rsa AAAAB3...yourkeyhere"
}

variable "cloud_exadata_infra_id" {
  description = "Cloud Exadata Infrastructure Resource ID"
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg000/providers/Oracle.Database/cloudExadataInfrastructures/infra1"
}

variable "vnet_id" {
  description = "Virtual Network Resource ID"
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg000/providers/Microsoft.Network/virtualNetworks/vnet1"
}

variable "subnet_id" {
  description = "Subnet Resource ID"
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg000/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/subnet1"
}

resource "azapi_resource" "resource_group" {
  type     = "Microsoft.Resources/resourceGroups@2023-07-01"
  name     = var.resource_group_name
  location = var.location
}

resource "azapi_resource" "cloud_exadata_infrastructure" {
  type      = "Oracle.Database/cloudExadataInfrastructures@2023-09-01-preview"
  parent_id = azapi_resource.resource_group.id
  name      = var.exa_cluster_name
  body = jsonencode({
    location = var.location,
    zones    = ["2"],
    tags     = {
      createdby = var.exa_cluster_name
    },
    properties = {
      computeCount = 2,
      displayName  = var.exa_cluster_name,
      maintenanceWindow = {
        leadTimeInWeeks = 0,
        preference      = "NoPreference",
        patchingMode    = "Rolling"
      },
      shape        = "Exadata.X9M",
      storageCount = 3
    }
  })
  schema_validation_enabled = false
}

resource "azapi_resource" "cloud_vm_cluster" {
  type                      = "Oracle.Database/cloudVmClusters@2023-09-01-preview"
  parent_id                 = azapi_resource.resource_group.id
  name                      = var.exa_cluster_name
  schema_validation_enabled = false
  depends_on                = [azapi_resource.cloud_exadata_infrastructure]
  body = jsonencode({
    properties = {
      dataStorageSizeInTbs       = 1000,
      dbNodeStorageSizeInGbs     = 1000,
      memorySizeInGbs            = 1000,
      timeZone                   = "UTC",
      hostname                   = "hostname1",
      domain                     = "domain1",
      cpuCoreCount               = 2,
      ocpuCount                  = 3,
      clusterName                = "cluster1",
      dataStoragePercentage      = 100,
      isLocalBackupEnabled       = false,
      cloudExadataInfrastructureId = var.cloud_exadata_infra_id,
      isSparseDiskgroupEnabled   = false,
      sshPublicKeys              = [var.ssh_public_key],
      nsgCidrs = [
        {
          source = "10.0.0.0/16"
          destinationPortRange = {
            min = 1520
            max = 1522
          }
        },
        {
          source = "10.10.0.0/24"
        }
      ],
      licenseModel           = "LicenseIncluded",
      scanListenerPortTcp    = 1050,
      scanListenerPortTcpSsl = 1025,
      vnetId                 = var.vnet_id,
      giVersion              = "19.0.0.0",
      subnetId               = var.subnet_id,
      backupSubnetCidr       = "172.17.5.0/24",
      dataCollectionOptions  = {
        isDiagnosticsEventsEnabled = false,
        isHealthMonitoringEnabled  = false,
        isIncidentLogsEnabled      = false
      },
      displayName = "Cluster 1",
      dbServers   = ["ocid1..aaaa"]
    },
    location = var.location
  })
  response_export_values = ["properties.ocid"]
}

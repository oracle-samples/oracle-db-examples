 terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azapi" {
  skip_provider_registration = false
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

locals {
  resource_group_name = "adbsdemotest"
  user                = "myuser"
  location            = "eastus"
}

# Create a resource group
resource "azapi_resource" "resource_group" {
  type     = "Microsoft.Resources/resourceGroups@2023-07-01"
  name     = local.resource_group_name
  location = local.location
}

# Create a virtual network
resource "azurerm_virtual_network" "virtual_network" {
  name                = "${local.resource_group_name}_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = local.location
  resource_group_name = local.resource_group_name
}

# Create a subnet with Oracle Database delegation
resource "azurerm_subnet" "virtual_network_subnet" {
  name                 = "${local.resource_group_name}_subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name = "Oracle.Database/networkAttachments"
    }
  }
}

# Fetch subnet details for later use
data "azurerm_subnet" "listSubnet" {
  name                 = azurerm_subnet.virtual_network_subnet.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  resource_group_name  = local.resource_group_name
  depends_on           = [azurerm_subnet.virtual_network_subnet]
}

# Generate an SSH private key
resource "tls_private_key" "generated_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create an SSH public key resource
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

# Deploy the Autonomous Database
resource "azapi_resource" "autonomousDbDeploy" {
  type                      = "Oracle.Database/autonomousDatabases@2023-09-01-preview"
  parent_id                 = azapi_resource.resource_group.id
  name                      = "Adbs_${local.resource_group_name}"
  schema_validation_enabled = false
  depends_on                = [azapi_resource.ssh_public_key]
  timeouts {
    create = "1h30m"
    update = "2h"
    delete = "20m"
  }
  body = jsonencode({
    location = local.location,
    tags = {
      createdby = local.user
    },
    properties = {
      subnetId           = data.azurerm_subnet.listSubnet.id,
      dataBaseType       = "Regular",
      displayName        = "example_autonomous_databasedb1",
      computeModel       = "ECPU",
      computeCount       = 2,
      dataStorageSizeInGbs = 32,
      dbWorkload         = "OLTP",
      adminPassword      = var.autonomous_db_admin_password, # Use variable for secure password management
      dbVersion          = "19c",
      characterSet       = "AL32UTF8",
      ncharacterSet      = "AL16UTF16",
      vnetId             = azurerm_virtual_network.virtual_network.id
    }
  })
  response_export_values = ["properties.ocid"]
}

# Output the OCID of the deployed Autonomous Database
output "autonomous_db_ocid" {
  value = azapi_resource.autonomousDbDeploy.response_export_values
}


resource "azapi_resource" "autonomousDbDeploy" {
  type                      = "Oracle.Database/autonomousDatabases@2023-09-01-preview"
  parent_id                 = azapi_resource.resource_group.id
  name                      = "Adbs${local.resource_group_name}"
  schema_validation_enabled = false
  timeouts {
    create = "1h30m"
    update = "2h"
    delete = "20m"
  }
  body = jsonencode({
    "location" : local.location,
    "tags" : {
      "createdby" : local.user
    },
    "properties" : {
      "subnetId" : data.azurerm_subnet.listSubnet.id
      "dataBaseType": "Regular",
      "displayName": "example_autonomous_databasedb1",
      "computeModel": "ECPU",
      "computeCount": 2,
      "dataStorageSizeInGbs": 32,
      "dbWorkload": "OLTP",
      "adminPassword": "Password",
      "dbVersion": "19c",
      "characterSet": "AL32UTF8",
      "ncharacterSet": "AL16UTF16",
      "vnetId": azurerm_virtual_network.virtual_network.id,
    }
  })
  response_export_values = ["properties.ocid"]
}

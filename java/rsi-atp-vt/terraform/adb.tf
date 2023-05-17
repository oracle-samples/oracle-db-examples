resource "oci_database_autonomous_database" "autonomous_database" {
  compartment_id              = var.compartment_ocid
  db_name                     = upper(replace(var.name, "-", ""))
  display_name                = format("%s%s", "adb-", var.name)
  db_workload                 = "OLTP"
  is_dedicated                = false
  is_free_tier                = false
  cpu_core_count              = 1
  data_storage_size_in_tbs    = 1
  admin_password              = var.adb_admin_password
  is_mtls_connection_required = true
  customer_contacts {
    email = var.adb_customer_contacts_email
  }
  
}

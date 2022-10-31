# general
variable "compartment_ocid" {
  type        = string
  default     = "<COMPARTMENT_OCID>"
  description = "OCID of your compartment"
}

# naming
variable "name" {
  type        = string
  default     = "<DB_NAME>"
  description = "ADB db name"
}

# adb
variable "adb_admin_password" {
  type        = string
  default     = "<DB_PASSWORD>"
  description = "ADB pw"
}
variable "adb_customer_contacts_email" {
  type        = string
  default     = "<EMAIL_ADDRESS>"
  description = "email address"
}

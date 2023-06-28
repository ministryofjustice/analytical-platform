resource "random_uuid" "openmetadata_jwt" {}

resource "random_password" "openmetadata_airflow" {
  length  = 32
  special = false
}

resource "random_password" "opensearch_master_password" {
  length           = 64
  special          = true
  override_special = "_%@"
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
}

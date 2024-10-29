locals {
  mojap_apc_prod_cadet_replication_bucket     = "mojap-compute-production-derived-tables-replication"
  mojap_apc_prod_cadet_replication_kms_key_id = "c85993f5-6182-4a01-a318-25c193cb9f65" #gitleaks:allow
  destination_region                          = "eu-west-1"
  default_region                              = "eu-west-1"
}

locals {
  mojap_apc_prod_cadet_replication_bucket     = "mojap-compute-production-derived-tables-replication"
  mojap_apc_prod_cadet_replication_kms_key_id = "c85993f5-6182-4a01-a318-25c193cb9f65" #gitleaks:allow
  mojap_apc_dev_cadet_replication_bucket      = "mojap-compute-development-derived-tables-replication"
  mojap_apc_dev_cadet_replication_kms_key_id  = "682a1072-23b1-4f75-b4ef-86e82bef2251" #gitleaks:allow
  destination_region                          = "eu-west-1"
  default_region                              = "eu-west-1"
}

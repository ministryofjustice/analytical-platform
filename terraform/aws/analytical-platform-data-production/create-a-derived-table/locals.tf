locals {
  mojap_apc_prod_cadet_replication_bucket     = "mojap-compute-production-derived-tables-replication"
  mojap_apc_prod_cadet_replication_kms_key_id = "1223ea30-ba03-487b-81dc-509126ac8a2b" #gitleaks:allow
  destination_region                          = "eu-west-1"
  default_region                              = "eu-west-1"
}

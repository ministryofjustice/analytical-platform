module "managed_prometheus" {
  source  = "terraform-aws-modules/managed-service-prometheus/aws"
  version = "2.2.2"

  workspace_alias = "open-metadata"
}

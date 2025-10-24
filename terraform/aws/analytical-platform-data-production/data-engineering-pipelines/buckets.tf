#trivy:ignore:avd-aws-0090:Bucket versioning is not preferred for query bucket
module "data_engineering_pipeline_buckets" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  for_each = local.data_engineering_buckets
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "5.8.2"

  bucket                               = each.key
  force_destroy                        = each.value.force_destroy
  object_lock_enabled                  = each.value.object_lock_enabled
  tags                                 = var.tags
  logging                              = each.value.logging
  server_side_encryption_configuration = each.value.server_side_encryption_configuration
  attach_policy                        = can(each.value.policy)
  policy                               = try(each.value.policy, null)
  lifecycle_rule                       = try(each.value.lifecycle_rule, [])
  versioning                           = try(each.value.versioning, null)
  attach_public_policy                 = true
  block_public_acls                    = try(each.value.public_access_block.block_public_acls, true)
  block_public_policy                  = try(each.value.public_access_block.block_public_policy, true)
  ignore_public_acls                   = try(each.value.public_access_block.ignore_public_acls, true)
  restrict_public_buckets              = try(each.value.public_access_block.restrict_public_buckets, true)
  grant                                = each.value.grant
}

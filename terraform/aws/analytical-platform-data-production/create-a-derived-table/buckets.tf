module "cadet_buckets" {
  for_each = local.cadet_buckets
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "4.2.0"

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

import {
  to = module.cadet_buckets["mojap-derived-tables"].aws_s3_bucket.this[0]
  id = "mojap-derived-tables"
}

import {
  to = module.cadet_buckets["mojap-derived-tables"].aws_s3_bucket_acl.this[0]
  id = "mojap-derived-tables"
}

import {
  to = module.cadet_buckets["mojap-derived-tables"].aws_s3_bucket_lifecycle_configuration.this[0]
  id = "mojap-derived-tables"
}

import {
  to = module.cadet_buckets["mojap-derived-tables"].aws_s3_bucket_policy.this[0]
  id = "mojap-derived-tables"
}

import {
  to = module.cadet_buckets["mojap-derived-tables"].aws_s3_bucket_public_access_block.this[0]
  id = "mojap-derived-tables"
}

import {
  to = module.cadet_buckets["mojap-derived-tables"].aws_s3_bucket_server_side_encryption_configuration.this[0]
  id = "mojap-derived-tables"
}

import {
  to = module.cadet_buckets["mojap-derived-tables"].aws_s3_bucket_versioning.this[0]
  id = "mojap-derived-tables"
}

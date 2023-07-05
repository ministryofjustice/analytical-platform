resource "aws_kms_key" "export_rds_snapshot_to_S3" {
  description              = "Export RDS snapshot to S3"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy                   = <<EOF
{
        "Id": "key-consolepolicy-3",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
}
EOF
}
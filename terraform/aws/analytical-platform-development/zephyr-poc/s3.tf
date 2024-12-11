module "airflow_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.2"

  bucket = local.bucket_name

  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.airflow_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

module "airflow_requirements_object" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.2.2"

  bucket        = module.airflow_bucket.s3_bucket_id
  key           = "requirements.txt"
  file_source   = "src/airflow/requirements.txt"
  force_destroy = true
}

module "airflow_local_settings_object" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.2.2"

  bucket        = module.airflow_bucket.s3_bucket_id
  key           = "dags/airflow_local_settings.py"
  file_source   = "src/airflow/dags/airflow_local_settings.py"
  force_destroy = true
}

resource "null_resource" "update_mwaa_environment" {
  triggers = {
    airflow_local_settings_object_version = module.airflow_local_settings_object.s3_object_version_id
  }
  provisioner "local-exec" {
    command = "bash contrib/update-mwaa-environment.sh ${var.account_ids["analytical-platform-development"]} ${local.mwaa_environment_name}"
  }
}

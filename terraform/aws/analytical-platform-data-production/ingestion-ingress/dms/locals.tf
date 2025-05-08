locals {
  analytical_platform_ingestion_environments = {
    development = {
      ingest_trusted_role_arns = [
        "arn:aws:iam::${var.account_ids["analytical-platform-ingestion-development"]}:role/tariff-development-metadata-generator",
        "arn:aws:iam::${var.account_ids["analytical-platform-ingestion-development"]}:role/tempus-cw-development-metadata-generator",
        "arn:aws:iam::${var.account_ids["analytical-platform-ingestion-development"]}:role/tempus-spppp-development-metadata-generator",
        "arn:aws:iam::${var.account_ids["analytical-platform-ingestion-development"]}:role/tempus-sppfj-development-metadata-generator"
      ]
    }
    production = {
      ingest_trusted_role_arns = [
        "arn:aws:iam::${var.account_ids["analytical-platform-ingestion-production"]}:role/tariff-production-metadata-generator",
        "arn:aws:iam::${var.account_ids["analytical-platform-ingestion-production"]}:role/tempus-cw-production-metadata-generator",
        "arn:aws:iam::${var.account_ids["analytical-platform-ingestion-production"]}:role/tempus-spppp-production-metadata-generator",
        "arn:aws:iam::${var.account_ids["analytical-platform-ingestion-production"]}:role/tempus-sppfj-production-metadata-generator"
      ]
    }
  }
}

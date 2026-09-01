import logging
import os
from typing import Optional
import uuid

import boto3

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

s3control = boto3.client("s3control")


def _manifest_filter(env, cutoff_date=None):

    manifest_filter = {
        "KeyNameConstraint": {
            "MatchAnyPrefix": [f"ppud_{env}/"],
        }
    }

    if cutoff_date:
        # Optional filter for migration windows. Must be ISO8601 if set.
        manifest_filter["CreatedBefore"] = cutoff_date

    return manifest_filter


def handler(_event=None, _context=None):

    account_id = os.environ["ACCOUNT_ID"]
    batch_copy_role_arn = os.environ["BATCH_COPY_ROLE_ARN"]
    source_bucket_arn = os.environ["SOURCE_BUCKET_ARN"]
    destination_bucket_arn = os.environ["DESTINATION_BUCKET_ARN"]
    manifest_bucket_arn = os.environ["MANIFEST_BUCKET_ARN"]
    env = os.environ["ENVIRONMENT"]
    cutoff_date = os.getenv("CUTOFF_DATE")

    response = s3control.create_job(
        AccountId=account_id,
        ConfirmationRequired=False,
        Operation={"S3PutObjectCopy": {"TargetResource": destination_bucket_arn}},
        Report={
            "Bucket": manifest_bucket_arn,
            "Prefix": "batch-copy/reports",
            "Format": "Report_CSV_20180820",
            "Enabled": True,
            "ReportScope": "AllTasks",
        },
        ManifestGenerator={
            "S3JobManifestGenerator": {
                "ExpectedBucketOwner": account_id,
                "SourceBucket": source_bucket_arn,
                "EnableManifestOutput": True,
                "ManifestOutputLocation": {
                    "ExpectedManifestBucketOwner": account_id,
                    "Bucket": manifest_bucket_arn,
                    "ManifestPrefix": "batch-copy/manifests",
                    "ManifestFormat": "S3InventoryReport_CSV_20211130",
                    "ManifestEncryption": {"SSES3": {}},
                },
                "Filter": _manifest_filter(env, cutoff_date),
            }
        },
        Priority=10,
        RoleArn=batch_copy_role_arn,
        ClientRequestToken=str(uuid.uuid4()),
        Description=(
            f"Copy files created before: {cutoff_date} "
            f"from {source_bucket_arn} to {destination_bucket_arn}."
        ),
    )

    job_id = response["JobId"]
    logger.info(
        f"Started S3 Batch Copy job: {job_id}: source={source_bucket_arn} "
        f"destination={destination_bucket_arn}, manifest_bucket={manifest_bucket_arn}"
        )

    return {
        "job_id": job_id,
        "source_bucket_arn": source_bucket_arn,
        "destination_bucket_arn": destination_bucket_arn,
        "manifest_bucket_arn": manifest_bucket_arn,
    }

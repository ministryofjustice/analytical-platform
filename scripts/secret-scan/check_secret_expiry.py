"""
Checks AWS Secrets Manager secrets for an `expiry-date` tag and reports their status.

Usage:
    python check_secret_expiry.py

Requirements:
    - AWS CLI/credentials configured with appropriate permissions.
    - boto3 library installed (pip install boto3).

Environment variables:
    GITHUB_STEP_SUMMARY: path to a file to append a markdown summary table to.
"""

import os
from datetime import datetime, timezone

import boto3

REGIONS = ["eu-west-1", "eu-west-2"]

WARNING_THRESHOLD_DAYS = 30
CRITICAL_THRESHOLD_DAYS = 7


def get_tagged_secrets(region):
    """
    Returns a list of (name, expiry_date, source_location) tuples for secrets
    in the given region that are tagged with `expiry-date`.
    """
    client = boto3.client("secretsmanager", region_name=region)
    secrets = []

    paginator = client.get_paginator("list_secrets")
    for page in paginator.paginate():
        for secret in page.get("SecretList", []):
            tags = {tag["Key"]: tag["Value"] for tag in secret.get("Tags", [])}
            if "expiry-date" not in tags:
                continue
            secrets.append(
                (
                    secret["Name"],
                    tags["expiry-date"],
                    tags.get("Source-location", "N/A"),
                )
            )

    return secrets


def get_status(days_remaining):
    if days_remaining < 0:
        return "EXPIRED"
    if days_remaining <= CRITICAL_THRESHOLD_DAYS:
        return "CRITICAL"
    if days_remaining <= WARNING_THRESHOLD_DAYS:
        return "WARNING"
    return "OK"


def main():
    today = datetime.now(timezone.utc).date()
    summary_rows = [
        "| Region | Secret name | Source-location | expiry-date | Status |",
        "|--------|-------------|------------------|-------------|--------|",
    ]

    for region in REGIONS:
        for name, expiry_date, source_location in get_tagged_secrets(region):
            try:
                expiry = datetime.strptime(expiry_date, "%Y-%m-%d").date()
            except ValueError:
                print(
                    f"::warning::Secret {name} in {region} has an unparsable expiry-date tag value: {expiry_date}"
                )
                continue

            days_remaining = (expiry - today).days
            status = get_status(days_remaining)

            if status == "EXPIRED":
                print(
                    f"::error::Secret {name} in {region} is EXPIRED (expiry-date: {expiry_date})"
                )
            elif status in ("CRITICAL", "WARNING"):
                print(
                    f"::warning::Secret {name} in {region} is {status} (expiry-date: {expiry_date})"
                )

            summary_rows.append(
                f"| {region} | {name} | {source_location} | {expiry_date} | {status} |"
            )

    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as summary_file:
            summary_file.write("\n".join(summary_rows) + "\n")
    else:
        print("\n".join(summary_rows))


if __name__ == "__main__":
    main()

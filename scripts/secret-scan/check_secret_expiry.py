"""
Checks AWS Secrets Manager secrets for an `expiry-date` tag and reports their status.

The script can scan:
- The AWS account represented by the credentials already configured in the runner.
- Additional AWS accounts by assuming a `github-actions-secret-check` role.

Usage:
    python check_secret_expiry.py

Requirements:
    - AWS credentials configured with appropriate permissions.
    - boto3 library installed.
    - The initial AWS role must have sts:AssumeRole permission for any
      additional target account roles.

Environment variables:
    GITHUB_STEP_SUMMARY: path to a file to append a markdown summary table to.
"""

import os
from datetime import datetime, timezone

import boto3

REGIONS = ["eu-west-1", "eu-west-2"]

WARNING_THRESHOLD_DAYS = 30
CRITICAL_THRESHOLD_DAYS = 7


# Accounts to scan.
#
# role_name = None means:
#   Use the AWS credentials already configured in the GitHub runner.
#
# For additional accounts, specify the role that should be assumed.
#
# Rename the account names below as appropriate once the mapping between
# account IDs and Analytical Platform environments is confirmed.
ACCOUNTS = {
    "analytical-platform-management-production": {
        "account_id": "042130406152",
        "role_name": None,
    },
    "analytical-platform-development": {
        "account_id": "525294151996",
        "role_name": "github-actions-secret-check",
    },
}


STATUS_PRIORITY = {
    "EXPIRED": 0,
    "CRITICAL": 1,
    "WARNING": 2,
    "INVALID": 3,
    "OK": 4,
}


def get_session(account_id, role_name=None):
    """
    Returns a boto3 Session.

    If role_name is provided, assumes that role in the target account first.
    Otherwise, uses the credentials already available to the runner.
    """
    if role_name is None:
        return boto3.Session()

    role_arn = f"arn:aws:iam::{account_id}:role/{role_name}"
    sts_client = boto3.client("sts")

    response = sts_client.assume_role(
        RoleArn=role_arn,
        RoleSessionName="github-actions-secret-expiry-check",
    )

    credentials = response["Credentials"]

    return boto3.Session(
        aws_access_key_id=credentials["AccessKeyId"],
        aws_secret_access_key=credentials["SecretAccessKey"],
        aws_session_token=credentials["SessionToken"],
    )


def get_tagged_secrets(session, region):
    """
    Returns secrets in the given region that have an `expiry-date` tag.

    Each returned dictionary contains:
        name
        expiry_date
        source_location
    """
    client = session.client("secretsmanager", region_name=region)
    secrets = []

    paginator = client.get_paginator("list_secrets")

    for page in paginator.paginate():
        for secret in page.get("SecretList", []):
            tags = {tag["Key"]: tag["Value"] for tag in secret.get("Tags", [])}

            if "expiry-date" not in tags:
                continue

            secrets.append(
                {
                    "name": secret["Name"],
                    "expiry_date": tags["expiry-date"],
                    "source_location": tags.get(
                        "source-location",
                        "N/A",
                    ),
                }
            )

    return secrets


def get_status(days_remaining):
    """
    Returns the expiry status based on the number of days remaining.
    """
    if days_remaining < 0:
        return "EXPIRED"

    if days_remaining <= CRITICAL_THRESHOLD_DAYS:
        return "CRITICAL"

    if days_remaining <= WARNING_THRESHOLD_DAYS:
        return "WARNING"

    return "OK"


def escape_markdown(value):
    """
    Escapes pipe characters so tag values or secret names do not break
    the GitHub Markdown table.
    """
    return str(value).replace("|", "\\|")


def main():
    today = datetime.now(timezone.utc).date()
    results = []

    for account_name, account_config in ACCOUNTS.items():
        account_id = account_config["account_id"]
        role_name = account_config["role_name"]

        print(f"Scanning account {account_name} " f"({account_id})")

        try:
            session = get_session(account_id, role_name)
        except Exception as exc:
            print(
                f"::warning::Unable to obtain credentials for "
                f"{account_name} ({account_id}): {exc}"
            )
            continue

        for region in REGIONS:
            print(f"Scanning {account_name} " f"({account_id}) in {region}")

            try:
                secrets = get_tagged_secrets(session, region)
            except Exception as exc:
                print(
                    f"::warning::Unable to scan Secrets Manager in "
                    f"{account_name} ({account_id}), {region}: {exc}"
                )
                continue

            for secret in secrets:
                name = secret["name"]
                expiry_date = secret["expiry_date"]
                source_location = secret["source_location"]

                try:
                    expiry = datetime.strptime(
                        expiry_date,
                        "%Y-%m-%d",
                    ).date()

                except ValueError:
                    status = "INVALID"

                    print(
                        f"::warning::Secret {name} in "
                        f"{account_name} ({account_id}), {region} "
                        f"has an unparsable expiry-date tag value: "
                        f"{expiry_date}"
                    )

                    results.append(
                        {
                            "account": account_name,
                            "account_id": account_id,
                            "region": region,
                            "name": name,
                            "source_location": source_location,
                            "expiry_date": expiry_date,
                            "days_remaining": "N/A",
                            "status": status,
                        }
                    )

                    continue

                days_remaining = (expiry - today).days
                status = get_status(days_remaining)

                if status == "EXPIRED":
                    print(
                        f"::error::Secret {name} in "
                        f"{account_name} ({account_id}), {region} "
                        f"is EXPIRED "
                        f"(expiry-date: {expiry_date})"
                    )

                elif status in ("CRITICAL", "WARNING"):
                    print(
                        f"::warning::Secret {name} in "
                        f"{account_name} ({account_id}), {region} "
                        f"is {status} "
                        f"(expiry-date: {expiry_date}, "
                        f"{days_remaining} days remaining)"
                    )

                results.append(
                    {
                        "account": account_name,
                        "account_id": account_id,
                        "region": region,
                        "name": name,
                        "source_location": source_location,
                        "expiry_date": expiry_date,
                        "days_remaining": days_remaining,
                        "status": status,
                    }
                )

    # Sort most urgent results first.
    #
    # Within each status, secrets with the fewest days remaining
    # appear first.
    def sort_key(result):
        days = result["days_remaining"]

        if isinstance(days, int):
            days_sort = days
        else:
            days_sort = float("inf")

        return (
            STATUS_PRIORITY[result["status"]],
            days_sort,
            result["account"],
            result["region"],
            result["name"],
        )

    results.sort(key=sort_key)

    summary_rows = [
        "## AWS Secret Expiry Check",
        "",
        f"Check date: `{today}`",
        "",
        (
            "| Account | Account ID | Region | Secret name | "
            "Source location | Expiry date | Days remaining | Status |"
        ),
        (
            "|---------|------------|--------|-------------|"
            "-----------------|-------------|----------------|--------|"
        ),
    ]

    for result in results:
        summary_rows.append(
            "| "
            f"{escape_markdown(result['account'])} | "
            f"{escape_markdown(result['account_id'])} | "
            f"{escape_markdown(result['region'])} | "
            f"{escape_markdown(result['name'])} | "
            f"{escape_markdown(result['source_location'])} | "
            f"{escape_markdown(result['expiry_date'])} | "
            f"{escape_markdown(result['days_remaining'])} | "
            f"{escape_markdown(result['status'])} |"
        )

    if not results:
        summary_rows.extend(
            [
                "",
                "No secrets with an `expiry-date` tag were found.",
            ]
        )

    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")

    if summary_path:
        with open(
            summary_path,
            "a",
            encoding="utf-8",
        ) as summary_file:
            summary_file.write("\n".join(summary_rows) + "\n")
    else:
        print("\n".join(summary_rows))


if __name__ == "__main__":
    main()

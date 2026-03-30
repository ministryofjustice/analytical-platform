#!/usr/bin/env python3
"""Create an OpenSearch Serverless index using SigV4 signed HTTP request."""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request

from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.session import Session


REGION = "eu-west-1"
SERVICE = "aoss"


def normalise_endpoint(endpoint: str) -> str:
    endpoint = endpoint.strip()
    if endpoint.startswith("http://") or endpoint.startswith("https://"):
        return endpoint.rstrip("/")
    return f"https://{endpoint.rstrip('/')}"


def main() -> int:
    if len(sys.argv) != 4:
        print(
            "Usage: create-opensearch-index.py <collection-endpoint> <index-name> <mapping-json-path>",
            file=sys.stderr,
        )
        return 2

    endpoint = normalise_endpoint(sys.argv[1])
    index_name = sys.argv[2]
    mapping_path = sys.argv[3]

    with open(mapping_path, "r", encoding="utf-8") as mapping_file:
        payload = mapping_file.read()

    # Validate JSON early to fail with a clear error message.
    json.loads(payload)

    url = f"{endpoint}/{index_name}"
    session = Session()
    credentials = session.get_credentials()
    if credentials is None:
        print("AWS credentials not found in environment", file=sys.stderr)
        return 1

    frozen_credentials = credentials.get_frozen_credentials()

    aws_request = AWSRequest(
        method="PUT",
        url=url,
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    SigV4Auth(frozen_credentials, SERVICE, REGION).add_auth(aws_request)

    request = urllib.request.Request(
        url=url,
        data=payload.encode("utf-8"),
        method="PUT",
        headers=dict(aws_request.headers.items()),
    )

    try:
        with urllib.request.urlopen(request) as response:
            body = response.read().decode("utf-8", errors="replace")
            print(body)
            return 0
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        # Treat existing index as success to keep apply idempotent.
        if error.code == 400 and "resource_already_exists_exception" in body:
            print("Index already exists")
            return 0
        print(body, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())


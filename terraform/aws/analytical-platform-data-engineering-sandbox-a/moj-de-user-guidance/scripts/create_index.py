#!/usr/bin/env python3

import argparse
import json
import sys

import boto3
import requests
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.session import Session


def sign_and_send(method: str, url: str, region: str, body: dict | None = None):
    session = Session()
    credentials = session.get_credentials()
    frozen = credentials.get_frozen_credentials()

    data = json.dumps(body) if body is not None else None
    headers = {"Content-Type": "application/json"}

    req = AWSRequest(method=method, url=url, data=data, headers=headers)
    SigV4Auth(frozen, "aoss", region).add_auth(req)

    prepared_headers = dict(req.headers.items())

    response = requests.request(
        method=method,
        url=url,
        data=data,
        headers=prepared_headers,
        timeout=120,
    )
    return response


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--region", required=True)
    parser.add_argument("--endpoint", required=True)
    parser.add_argument("--index-name", required=True)
    parser.add_argument("--vector-field", required=True)
    parser.add_argument("--text-field", required=True)
    parser.add_argument("--metadata-field", required=True)
    parser.add_argument("--dimensions", required=True, type=int)
    args = parser.parse_args()

    endpoint = args.endpoint.rstrip("/")
    index_url = f"{endpoint}/{args.index_name}"

    # Check whether index already exists
    check = sign_and_send("HEAD", index_url, args.region)
    if check.status_code == 200:
        print(f"Index {args.index_name} already exists")
        return 0

    if check.status_code not in (404, 403):
        print(f"Unexpected HEAD response: {check.status_code} {check.text}", file=sys.stderr)

    body = {
        "settings": {
            "index": {
                "knn": True
            }
        },
        "mappings": {
            "properties": {
                args.vector_field: {
                    "type": "knn_vector",
                    "dimension": args.dimensions,
                    "method": {
                        "name": "hnsw",
                        "engine": "faiss",
                        "space_type": "l2"
                    }
                },
                args.text_field: {
                    "type": "text",
                    "index": True
                },
                args.metadata_field: {
                    "type": "text",
                    "index": False
                }
            }
        }
    }

    create = sign_and_send("PUT", index_url, args.region, body=body)
    print(create.status_code)
    print(create.text)

    if create.status_code not in (200, 201):
        raise SystemExit(f"Failed to create index: {create.status_code}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
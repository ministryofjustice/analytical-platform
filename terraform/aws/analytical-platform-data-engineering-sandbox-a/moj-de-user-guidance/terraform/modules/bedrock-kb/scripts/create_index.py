import argparse
import json
import sys
import time

import requests
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.session import Session

parser = argparse.ArgumentParser()
parser.add_argument("--region", required=True)
parser.add_argument("--endpoint", required=True)
parser.add_argument("--index-name", required=True)
parser.add_argument("--vector-field", required=True)
parser.add_argument("--text-field", required=True)
parser.add_argument("--metadata-field", required=True)
parser.add_argument("--dimensions", type=int, required=True)
args = parser.parse_args()

# Print caller identity for debugging
session = Session()
sts = session.create_client("sts", region_name=args.region)
identity = sts.get_caller_identity()
print(f"Caller Identity: {identity['Arn']}")
print(f"Account: {identity['Account']}")

url = f"{args.endpoint}/{args.index_name}"

body = {
    "settings": {"index": {"knn": True}},
    "mappings": {
        "properties": {
            args.vector_field: {
                "type": "knn_vector",
                "dimension": args.dimensions,
                "method": {"engine": "faiss"},
            },
            args.text_field: {"type": "text"},
            args.metadata_field: {"type": "text"},
        }
    },
}

max_retries = 5
retry_delay = 60

for attempt in range(1, max_retries + 1):
    print(f"\nAttempt {attempt}/{max_retries}")

    creds = session.get_credentials().get_frozen_credentials()
    req = AWSRequest(
        method="PUT",
        url=url,
        data=json.dumps(body),
        headers={"Content-Type": "application/json"},
    )
    SigV4Auth(creds, "aoss", args.region).add_auth(req)

    try:
        resp = requests.put(url, headers=dict(req.headers), data=req.data, timeout=30)
        print(f"Status: {resp.status_code}")
        print(f"Response: {resp.text}")

        if resp.status_code in [200, 201]:
            print("Index created successfully.")
            sys.exit(0)

        if "resource_already_exists_exception" in resp.text.lower():
            print("Index already exists. Skipping.")
            sys.exit(0)

        if resp.status_code == 403 and attempt < max_retries:
            print("Got 403. Data access policy may still be propagating.")
            print(f"Waiting {retry_delay}s before retry...")
            time.sleep(retry_delay)
            continue

        if resp.status_code == 403 and attempt == max_retries:
            print("ERROR: Still getting 403 after all retries.")
            print(
                "Check that the following principal is in the AOSS data access policy:"
            )
            print(f"  {identity['Arn']}")
            sys.exit(1)

        # Any other error
        print(f"Unexpected status code: {resp.status_code}")
        sys.exit(1)

    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")
        if attempt < max_retries:
            print(f"Waiting {retry_delay}s before retry...")
            time.sleep(retry_delay)
        else:
            print("All retries exhausted.")
            sys.exit(1)
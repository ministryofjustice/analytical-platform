#!/usr/bin/env bash

set -euxo pipefail

mkdir --parents src

for bucket in $( aws s3api list-buckets | jq -r '.Buckets[] | select(.Name | startswith("alpha")) | .Name' ); do
  bucketPolicy=$( aws s3api get-bucket-policy --bucket ${bucket} 2>/dev/null | jq -r '.Policy' )
  if [[ "${bucketPolicy}" != *"DenyInsecureTransport"* ]]; then
    echo $( cat policy.json.tmpl | sed "s|BUCKET_NAME|${bucket}|g" ) > src/policy-${bucket}.json
    aws s3api put-bucket-policy --bucket ${bucket} --policy file://src/policy-${bucket}.json
  fi
  sleep 5
done

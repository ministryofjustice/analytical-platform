#!/usr/bin/env bash

export UUID=$(uuidgen)
export TTL="5h"

docker build --platform linux/amd64 --tag ttl.sh/${UUID}:${TTL} .

docker push ttl.sh/${UUID}:${TTL}

echo "ttl.sh/${UUID}:${TTL}"

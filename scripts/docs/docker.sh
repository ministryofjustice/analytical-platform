#!/usr/bin/env bash

MODE="${1}"
IMAGE="docker.io/ministryofjustice/tech-docs-github-pages-publisher:ministryofjustice-fork"

case ${MODE} in
  deploy|preview|check-url-links)
    true
  ;;
  *)
    echo "Usage: ${0} [deploy|preview|check-url-links]"
    exit 1
  ;;
esac

if [[ "$(uname -m)" == "aarch64" ]] || [[ "$(uname -m)" == "arm64" ]]; then
  PLATFORM_FLAG="--platform linux/amd64"
else
  PLATFORM_FLAG=""
fi

docker run -it --rm ${PLATFORM_FLAG} \
  --name tech-docs-${MODE} \
  --publish 4567:4567 \
  --volume $(pwd)/docs/config:/app/config \
  --volume $(pwd)/docs/source:/app/source \
  ${IMAGE} /scripts/${MODE}.sh

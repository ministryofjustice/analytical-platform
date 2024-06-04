#!/usr/bin/env bash

MODE="${1:-preview}"
TECH_DOCS_PUBLISHER_IMAGE="docker.io/ministryofjustice/tech-docs-github-pages-publisher@sha256:cd3513beca3fcaf5dd34cbe81a33b3ff30337d8ada5869b40a6454c21d6f7684" # v4.0.0

case ${MODE} in
package | preview)
  true
  ;;
*)
  echo "Usage: ${0} [package|preview]"
  exit 1
  ;;
esac

if [[ "$(uname --machine)" == "aarch64" ]] || [[ "$(uname --machine)" == "arm64" ]]; then
  PLATFORM_FLAG="--platform=linux/amd64"
else
  PLATFORM_FLAG=""
fi

docker run -it --rm ${PLATFORM_FLAG} \
  --name "tech-docs-${MODE}" \
  --publish 4567:4567 \
  --volume "${PWD}/config:/app/config" \
  --volume "${PWD}/source:/app/source" \
  "${TECH_DOCS_PUBLISHER_IMAGE}" "/usr/local/bin/${MODE}"

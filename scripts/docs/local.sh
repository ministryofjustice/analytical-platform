#!/usr/bin/env bash

MODE="${1:-preview}"
TECH_DOCS_PUBLISHER_IMAGE="ghcr.io/ministryofjustice/tech-docs-github-pages-publisher@sha256:35699473dbeefeeb8b597de024125a241277ee03587d5fe8e72545e4b27b33f8" # v5.0.0

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

docker run -it --rm "${PLATFORM_FLAG}" \
  --name "tech-docs-${MODE}" \
  --publish 4567:4567 \
  --volume "${PWD}/config:/tech-docs-github-pages-publisher/config" \
  --volume "${PWD}/source:/tech-docs-github-pages-publisher/source" \
  "${TECH_DOCS_PUBLISHER_IMAGE}" "/usr/local/bin/${MODE}"

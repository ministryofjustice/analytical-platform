#!/usr/bin/env bash

docker run -it --rm \
  --name docs-serve \
  --volume "${PWD}"/docs:/docs \
  --volume "${PWD}"/scripts/docs/serve.sh:/usr/local/bin/serve.sh \
  --workdir /docs \
  --publish 8080:8080 \
  --entrypoint /bin/bash \
  --user 1000:1000 \
  public.ecr.aws/docker/library/node:hydrogen-bookworm \
  /usr/local/bin/serve.sh

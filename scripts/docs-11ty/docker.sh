#!/usr/bin/env bash

docker run -it --rm \
  --volume "${PWD}"/docs-11ty:/docs \
  --volume "${PWD}"/scripts/docs-11ty/run.sh:/usr/local/bin/run.sh \
  --workdir /docs \
  --publish 8080:8080 \
  --entrypoint /bin/bash \
  --user 1000:1000 \
  public.ecr.aws/docker/library/node:lts-bookworm \
  /usr/local/bin/run.sh

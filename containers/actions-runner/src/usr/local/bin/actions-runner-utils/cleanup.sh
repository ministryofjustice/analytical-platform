#/usr/local/bin/env bash

ACTIONS_RUNNER_DIRECTORY="/actions-runner"

echo "Removing runner"
bash "${ACTIONS_RUNNER_DIRECTORY}/config.sh" \
  remove \
  --token "${REPO_TOKEN}"

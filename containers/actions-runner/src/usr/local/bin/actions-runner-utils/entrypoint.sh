#/usr/local/bin/env bash

ACTIONS_RUNNER_DIRECTORY="/actions-runner"

echo "Configuring runner"

bash "${ACTIONS_RUNNER_DIRECTORY}/config.sh" \
  --unattended \
  --ephemeral  \
  --disableupdate \
  --url "${REPO_URL}" \
  --token "${REPO_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}"

echo "Starting runner"

bash "${ACTIONS_RUNNER_DIRECTORY}/run.sh"

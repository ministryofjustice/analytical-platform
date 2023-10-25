#/usr/local/bin/env bash

ACTIONS_RUNNER_DIRECTORY="/actions-runner"

echo "Configuring runner"

if [[ -z "${RUNNER_NAME_PREFIX}" ]]; then
  RUNNER_NAME="${RUNNER_NAME}"
else
  RUNNER_NAME="${RUNNER_NAME_PREFIX}-$(hostname)"
fi

bash "${ACTIONS_RUNNER_DIRECTORY}/config.sh" \
  --unattended \
  --disableupdate \
  --url "${REPO_URL}" \
  --token "${REPO_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}"

echo "Starting runner"

bash "${ACTIONS_RUNNER_DIRECTORY}/run.sh"

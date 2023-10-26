#/usr/local/bin/env bash

ACTIONS_RUNNER_DIRECTORY="/actions-runner"

echo "Runner parameters:"
echo "  Repository: ${GITHUB_REPOSITORY}"
echo "  Runner Name: ${RUNNER_NAME}"
echo "  Runner Labels: ${RUNNER_LABELS}"

echo "Obtaining registration token"
getRegistrationToken=$(curl \
  --silent \
  --location \
  --request "POST" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  --header "Authorization: Bearer ${GITHUB_TOKEN}" \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token | jq -r '.token'
)
export getRegistrationToken

echo "Checking if registration token exists"
if [[ -z "${getRegistrationToken}" ]]; then
  echo "Failed to obtain registration token"
  exit 1
else
  echo "Registration token obtained successfully"
  REPO_TOKEN="${getRegistrationToken}"
fi

echo "Configuring runner"
bash "${ACTIONS_RUNNER_DIRECTORY}/config.sh" \
  --unattended \
  --disableupdate \
  --url "https://github.com/${GITHUB_REPOSITORY}" \
  --token "${REPO_TOKEN}" \
  --name "$(hostname)" \
  --labels "${RUNNER_LABELS}"

echo "Starting runner"
bash "${ACTIONS_RUNNER_DIRECTORY}/run.sh"

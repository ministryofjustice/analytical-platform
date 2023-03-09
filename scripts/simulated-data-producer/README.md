# Simulated Data Producer

## Requirements

- Kubernetes CLI

  - Configured with Cloud Platform credentials from
    <https://login.cloud-platform.service.justice.gov.uk>

- Cloud Platform CLI

## Execute

From <https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/rds-external-access.html#accessing-your-rds-database>

1. Run port-forward pod

   ```bash
   export KUBERNETES_NAMESPACE="data-platform-development"
   export KUBERNETES_POD="port-forward"
   export KUBERNETES_SECRET="cloud-platform-simulated-data-producer-rds"
   export PORT_FORWARD_IMAGE="docker.io/ministryofjustice/port-forward:1.0"
   export PORT_FORWARD_LOCAL_PORT="5432"
   export PORT_FORWARD_REMOTE_HOST=$( cloud-platform decode-secret \
    --namespace ${KUBERNETES_NAMESPACE} \
    --secret ${KUBERNETES_SECRET} | jq -r '.data.rds_instance_address' )
   export PORT_FORWARD_REMOTE_PORT="5432"

   kubectl \
     --namespace ${KUBERNETES_NAMESPACE} \
     run \
     ${KUBERNETES_POD} \
     --image ${PORT_FORWARD_IMAGE} \
     --env LOCAL_PORT=${PORT_FORWARD_LOCAL_PORT} \
     --env REMOTE_HOST=${PORT_FORWARD_REMOTE_HOST} \
     --env REMOTE_PORT=${PORT_FORWARD_REMOTE_PORT} \
     --port ${PORT_FORWARD_REMOTE_PORT}
   ```

1. Port forward in to background

   ```bash
   kubectl \
     --namespace ${KUBERNETES_NAMESPACE} \
     port-forward \
     ${KUBERNETES_POD} \
     ${PORT_FORWARD_LOCAL_PORT}:${PORT_FORWARD_REMOTE_PORT} &

   export portForwardPid=${!}
   ```

1. Run script

   ```bash
   export DB_ENDPOINT="127.0.0.1"
   export DB_PORT="${PORT_FORWARD_LOCAL_PORT}"
   export DB_USERNAME=$( cloud-platform decode-secret \
     --namespace ${KUBERNETES_NAMESPACE} \
     --secret ${KUBERNETES_SECRET} | jq -r '.data.database_username' )
   export DB_PASSWORD=$( cloud-platform decode-secret \
     --namespace ${KUBERNETES_NAMESPACE} \
     --secret ${KUBERNETES_SECRET} | jq -r '.data.database_password' )

   python main.py
   ```

1. Delete pod

   ```bash
   kubectl \
     --namespace ${KUBERNETES_NAMESPACE} \
     delete \
     pod \
     ${KUBERNETES_POD}
   ```

1. Close background port forward

   ```bash
   kill -9 ${portForwardPid}
   ```

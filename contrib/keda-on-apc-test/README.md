# KEDA on APC Test

1. Connect to APC Test

    ```bash
    kubectl config use-context arn:aws:eks:eu-west-2:767397661611:cluster/analytical-platform-compute-test
    ```

1. Create namespaces

    ```bash
    kubectl apply --filename namespaces.yml
    ```

1. Deploy KEDA Helm chart

    ```bash
    helm repo add kedacore https://kedacore.github.io/charts

    helm repo update

    helm install keda kedacore/keda --namespace keda
    ```

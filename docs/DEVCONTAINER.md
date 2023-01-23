# Data Platform Development Container

## Prerequisites

* macOS

* Docker for Mac or Rancher Desktop

* Node / NPM

* devcontainer CLI

* Visual Studio Code

  * Dev Containers Extension

## Using

1. Update your `~/.bashrc` or `~/.zshrc` to export your AWS IAM email address (Temporary until we all use AWS SSO)

    ```bash
    export MOJ_DP_AWS_IAM_EMAIL="firstname.lastname@digital.justice.gov.uk"
    ```

1. Launch Visual Studio Code

1. Reopen in Container

## Developing

### Testing

1. Build base image

    ```bash
    docker build --file .devcontainer/src/Dockerfile --tag moj-devcontainer-test .devcontainer/src
    ```

1. Test feature

    ```bash
    devcontainer features test --features aws-vault --base-image moj-devcontainer-test
    ```

### Debug Locally

1. Run base image

    ```bash
    docker run -it --rm \
        --volume $( pwd ):/workspace \
        --volume $( pwd )/.devcontainer/src/usr/local/bin/devcontainer/shared-library:/usr/local/bin/devcontainer/shared-library \
        mcr.microsoft.com/devcontainers/base:ubuntu
    ```

1. Test feature

    ```bash
    bash /workspace/.devcontainer/features/src/${FEATURE}/install.sh
    ```

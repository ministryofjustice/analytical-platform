# Data Platform Development Container

## Prerequisites

* macOS

* Homebrew

    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

* Docker for Mac or Rancher Desktop

    ```bash
    brew install --cask rancher
    ```

* Node / NPM

    ```bash
    brew install node
    ```

* devcontainer CLI

    ```bash
    npm install --global @devcontainers/cli@latest
    ```

* Visual Studio Code

    ```bash
    brew install --cask visual-studio-code
    ```

  * Dev Containers Extension

    This command could fail as `code` might not be in your `${PATH}` yet, if that is the case, install it via Visual Studio Code's UI

    ```bash
    /usr/local/bin/code --install-extension ms-vscode-remote.remote-containers
    ```

## Using

1. Update your `~/.bashrc` or `~/.zshrc` to export your AWS IAM email address (Temporary until we all use AWS SSO)

    ```bash
    export MOJ_DATA_PLATFORM_AWS_IAM_EMAIL="firstname.lastname@digital.justice.gov.uk"
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
    bash -x /workspace/.devcontainer/features/src/${FEATURE}/install.sh
    ```

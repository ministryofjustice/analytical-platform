#!/usr/bin/env bash

install --mode=0600 .devcontainer/src/kubernetes/config /home/vscode/.kube/config

sudo install --mode=0770 --owner=vscode --group=vscode .devcontainer/src/kubernetes/aws-sso-eks-auth.sh /usr/local/bin/aws-sso-eks-auth

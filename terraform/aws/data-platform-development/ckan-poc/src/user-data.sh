#!/usr/bin/env bash

sudo dnf install --assumeyes docker

sudo systemctl --now enable docker

sudo curl --location https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

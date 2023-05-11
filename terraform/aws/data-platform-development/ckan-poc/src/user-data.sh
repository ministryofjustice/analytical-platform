#!/usr/bin/env bash

##################################################
# Install Prerequisite Packages
##################################################

dnf install --assumeyes \
  git

##################################################
# Install Docker and Docker Compose
##################################################

export DOCKER_COMPOSE_VERSION="2.17.3"

dnf install --assumeyes docker

systemctl --now enable docker

curl --location https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

##################################################
# Install CKAN
##################################################

export _CKAN_ROOT_DIRETORY="/srv/ckan"

# NonProd MP workloads get shutdown between 20:00 and 05:00, so we need to start CKAN on boot

cat >/etc/systemd/system/ckan-docker.service <<EOF
[Unit]
Description=CKAN Docker
Requires=docker.service
After=docker.service

[Service]
Restart=always
WorkingDirectory=${_CKAN_ROOT_DIRETORY}/ckan-docker
ExecStartPre=/usr/local/bin/docker-compose --file docker-compose.yml build
ExecStart=/usr/local/bin/docker-compose --file docker-compose.yml up
ExecStop=/usr/local/bin/docker-compose --file docker-compose.yml down

[Install]
WantedBy=multi-user.target
EOF

mkdir --parents ${_CKAN_ROOT_DIRETORY}

cd ${_CKAN_ROOT_DIRETORY}

git clone https://github.com/ckan/ckan-docker.git

cd ckan-docker

mv --force .env.example .env

systemctl --now enable ckan-docker

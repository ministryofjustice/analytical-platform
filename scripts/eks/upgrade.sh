#!/usr/bin/env bash

OLD_VERSION="1.28"
NEW_VERSION="1.29"


while true; do
  oldNodeCount=$(kubectl get nodes | grep "${OLD_VERSION}" | wc -l)
  newNodeCount=$(kubectl get nodes | grep "${NEW_VERSION}" | wc -l)

  echo "$(date)"
  echo "${OLD_VERSION}: ${oldNodeCount}"
  echo "${NEW_VERSION}: ${newNodeCount}"

  sleep 10

  clear
done

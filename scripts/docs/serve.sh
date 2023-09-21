#!/usr/bin/env bash

mkdir -p "${HOME}"/.npm

npm install

npx eleventy --serve

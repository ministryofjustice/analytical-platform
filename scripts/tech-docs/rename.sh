#!/usr/bin/env bash

# Compile source markdown files into HTML in the `/docs` directory
bundle exec middleman build --build-dir docs --relative-links --verbose

touch docs/.nojekyll

# Internal link check only within the docs folder
htmlproofer --log-level debug --allow-missing-href true --disable_external true ./docs

tar --dereference --directory docs -cvf artifact.tar --exclude=.git --exclude=.github .

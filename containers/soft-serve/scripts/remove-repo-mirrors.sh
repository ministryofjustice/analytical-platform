#!/bin/bash

# Function to import a repository
remove_repo() {
    local host="127.0.0.1"
    local port="23231"
    local keyfile="/home/softserve/.ssh/id_rsa"
    local repo_name="$1"

    ssh -p "$port" -i "$keyfile" "$host" repo delete "$repo_name"
    echo "🧹 Removing" $repo_name "mirror..."
}

# List of repositories to import (add more as needed)
repos=(
    "data-platform"
    "cloud-platform-environments"
)

# Loop through the list and import repositories
for repo in "${repos[@]}"; do
    remove_repo $repo
done

echo "🪦 All repository mirrors removed."
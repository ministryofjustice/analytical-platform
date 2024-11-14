#!/usr/bin/env bash

# Generate the list of user namespaces
kubectl get namespaces -A | grep user | awk '{print $1}' > user-namespaces.txt

# Create or clear the output file
> image-tag-summary.txt

# Define a function to print a formatted line
print_line() {
    printf "%-40s %-25s %-15s\n" "$1" "$2" "$3" >> image-tag-summary.txt
}

# Initialize associative arrays for tracking versions
declare -A version_count
declare -A version_namespaces

# Iterate over each namespace
while IFS= read -r namespace; do
    echo "Namespace: $namespace" >> image-tag-summary.txt
    echo "---------------------" >> image-tag-summary.txt
    print_line "Deployment" "Tool" "Version"

    # Get the list of deployments in the current namespace
    deployments=$(kubectl -n "$namespace" get deployments | awk 'NR>1 {print $1}')

    # Iterate over each deployment
    for deployment in $deployments; do
        # Skip scheduler deployments
        if [[ "$deployment" == *"scheduler"* ]]; then
            continue
        fi

        # Initialize a flag to check if any version is found
        version_found=false

        # Function to process version
        process_version() {
            local tool=$1
            local version=$2
            if [ -n "$version" ]; then
                print_line "$deployment" "$tool" "$version"
                version_found=true
                version_count["$version"]=$((version_count["$version"] + 1))
                if [[ ! "${version_namespaces[$version]}" =~ "$namespace" ]]; then
                    version_namespaces["$version"]+="$namespace, "
                fi
            fi
        }

        # Check for vscode image version
        vscode_version=$(kubectl -n "$namespace" describe deployment "$deployment" | \
        grep "Image:.*analytical-platform-visual-studio-code" | \
        awk '{print $2}' | cut -d':' -f2)
        process_version "VSCode" "$vscode_version"

        # Check for rstudio image version
        rstudio_version=$(kubectl -n "$namespace" describe deployment "$deployment" | \
        grep "Image:.*rstudio" | \
        awk '{print $2}' | cut -d':' -f2)
        process_version "RStudio" "$rstudio_version"

        # Check for allspark-notebook image version
        allspark_version=$(kubectl -n "$namespace" describe deployment "$deployment" | \
        grep "Image:.*allspark-notebook" | \
        awk '{print $2}' | cut -d':' -f2)
        process_version "Allspark Notebook" "$allspark_version"

        # Check for datascience-notebook image version
        datascience_version=$(kubectl -n "$namespace" describe deployment "$deployment" | \
        grep "Image:.*datascience-notebook" | \
        awk '{print $2}' | cut -d':' -f2)
        process_version "Data Science Notebook" "$datascience_version"

        # If no version was found, indicate that
        if [ "$version_found" = false ]; then
            print_line "$deployment" "None" "No relevant image version found"
        fi
    done

    # Add a newline for separation between namespaces
    echo "" >> image-tag-summary.txt
done < user-namespaces.txt

# Print summary
echo "Version Summary:" >> image-tag-summary.txt
echo "----------------" >> image-tag-summary.txt
for version in "${!version_count[@]}"; do
    echo "Version: $version, Count: ${version_count[$version]}" >> image-tag-summary.txt
    echo "Users: ${version_namespaces[$version]%, }" >> image-tag-summary.txt
    echo "" >> image-tag-summary.txt
done

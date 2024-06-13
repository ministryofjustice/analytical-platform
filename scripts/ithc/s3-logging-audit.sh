#!/usr/bin/env bash

# File to store output
output_file="access-logging-disabled-2.json"

# Initialize JSON file
echo "[]" > $output_file

# List all S3 buckets
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Maximum parallel jobs
max_jobs=10

# Current number of parallel jobs
job_count=0

# Initialize counters for logging status
logging_enabled_count=0
logging_disabled_count=0

# Function to process each bucket
process_bucket() {
    local bucket=$1
    echo "🪣  Checking bucket: $bucket"
    local logging=$(aws s3api get-bucket-logging --bucket $bucket --output json)

    # Handle error in fetching logging info
    if [ $? -ne 0 ]; then
        echo "Failed to get logging information for $bucket"
        return
    fi

    # Check if logging is enabled
    if [[ $logging == "{}" || $logging == "" ]]; then
        echo "❌ Access Logging is NOT enabled for $bucket"
        (( logging_disabled_count++ ))

        # Get the last object's last modified info and use a safer approach to parse it
        local last_object=$(aws s3api list-objects-v2 --bucket $bucket --query 'Contents | sort_by(@, &LastModified)[-1]' --output json)
        if [ $? -ne 0 ] || [ "$last_object" == "null" ]; then
            echo "Error fetching objects or no objects in bucket $bucket"
            local last_modified_date="N/A"
            local last_modified_key="N/A"
            local total_objects=0
            local total_size=0
        else
            local last_modified_date=$(echo "$last_object" | jq -r '.LastModified' 2>/dev/null)
            local last_modified_key=$(echo "$last_object" | jq -r '.Key' 2>/dev/null)

            # Fetch object count and total size
            local object_stats=$(aws s3api list-objects-v2 --bucket $bucket --output json)
            local total_objects=$(echo "$object_stats" | jq '.KeyCount')
            local total_size=$(echo "$object_stats" | jq '[.Contents[].Size] | add' 2>/dev/null || echo 0)
        fi

        # Build JSON object
        local bucket_info=$(jq -n \
                            --arg bn "$bucket" \
                            --arg lm "$last_modified_date" \
                            --arg lk "$last_modified_key" \
                            --argjson to "$total_objects" \
                            --argjson ts "$total_size" \
                            '{bucket_name: $bn, last_modified_date: $lm, last_modified_key: $lk, total_objects: $to, total_size: $ts}')

        # Append JSON object to the file
        jq ". += [$bucket_info]" $output_file > tmp.json && mv tmp.json $output_file
    else
        echo "✅ Access Logging is enabled for $bucket"
        (( logging_enabled_count++ ))
    fi
}

# Process each bucket in parallel up to max_jobs
for bucket in $buckets; do
    process_bucket "$bucket" &  # Run in background

    # Manage parallelism
    ((job_count++))
    if (( job_count >= max_jobs )); then
        wait # Wait for all parallel jobs to finish
        job_count=0
    fi
done

wait # Wait for remaining jobs to finish if any

# Output the result
cat $output_file

# Summary of enabled/disabled logging
echo "Summary:"
echo "Total buckets with Access Logging enabled: $logging_enabled_count"
echo "Total buckets with Access Logging NOT enabled: $logging_disabled_count"

#!/usr/bin/env bash

# Bucket for storing access logs
log_target_bucket="moj-analytics-s3-logs"

# List of buckets where access logging is disabled
buckets_to_enable_logging=("user-guidance.services.alpha.mojanalytics.xyz-cloudfront-logs")

# Enable access logging for each bucket
for bucket in "${buckets_to_enable_logging[@]}"; do
  echo "🪣 Enabling access logging for bucket: $bucket"

  # Set the logging configuration
  aws s3api put-bucket-logging --bucket "$bucket" \
    --bucket-logging-status '{
      "LoggingEnabled": {
        "TargetBucket": "'$log_target_bucket'",
        "TargetPrefix": "'$bucket/'"
      }
    }'

  # Check if the command was successful
  if [ $? -ne 0 ]; then
    echo "❌ Failed to enable logging for bucket: $bucket"
  else
    echo "✅ Access logging enabled for bucket: $bucket"
  fi
done

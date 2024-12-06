import boto3
import datetime
import json
import base64
import gzip
import os
from io import BytesIO


CLOUDWATCH_LOG_GROUP_NAME = os.environ['CLOUDWATCH_LOG_GROUP_NAME']
CLOUDWATCH_LOG_STREAM_NAME = datetime.datetime.now().strftime('%Y-%m-%d')

logs_client = boto3.client('logs')

def lambda_handler(event, context):
    # Extract and decode the data
    compressed_data = base64.b64decode(event['awslogs']['data'])

    # Decompress the data
    with gzip.GzipFile(fileobj=BytesIO(compressed_data)) as gzipfile:
        decompressed_data = gzipfile.read()

    # Parse the JSON data
    parsed_event = json.loads(decompressed_data)

    # Process the log events
    for log_event in parsed_event['logEvents']:
        print(f"Processing log event: {log_event['id']}")

        # Get the timestamp from the log event
        timestamp = log_event['timestamp']

        # Get the message from the log event
        message = json.loads(log_event['message'])

        # Create a log stream
        try:
            response = logs_client.create_log_stream(
                logGroupName=CLOUDWATCH_LOG_GROUP_NAME,
                logStreamName=CLOUDWATCH_LOG_STREAM_NAME
            )
        except logs_client.exceptions.ResourceAlreadyExistsException:
            pass

        # Put the log event in the log stream
        response = logs_client.put_log_events(
            logGroupName=CLOUDWATCH_LOG_GROUP_NAME,
            logStreamName=CLOUDWATCH_LOG_STREAM_NAME,
            logEvents=[
                {
                    'timestamp': timestamp,
                    'message': json.dumps(message)
                }
            ]
        )

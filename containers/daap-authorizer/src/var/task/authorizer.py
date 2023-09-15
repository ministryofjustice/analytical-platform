import json
import os

from data_platform_logging import DataPlatformLogger

logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)


def handler(event, context):
    logger.info(f"event: {event}")

    authorizationToken = json.dumps(event["authorizationToken"])
    characters_to_remove = '"[]"'
    for character in characters_to_remove:
        authorizationToken = authorizationToken.replace(character, "")

    auth = "Allow" if authorizationToken == os.environ["authorizationToken"] else "Deny"

    authResponse = {
        "principalId": "abc123",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Resource": [os.environ["api_resource_arn"]],
                    "Effect": auth,
                }
            ],
        },
    }

    return authResponse

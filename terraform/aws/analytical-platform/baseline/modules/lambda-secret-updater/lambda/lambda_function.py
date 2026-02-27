import os
import boto3

s3 = boto3.client("s3")
secrets = boto3.client("secretsmanager")

BUCKET = os.environ["BUCKET_NAME"]
KEY = os.environ["OBJECT_KEY"]
SECRET_NAME = os.environ["SECRET_NAME"]

MARKER = "SAS URL:"


def extract_sas_url(content: str) -> str:
    lines = content.splitlines()

    for i, line in enumerate(lines):
        if MARKER in line:
            # Look at lines after MARKER"
            for next_line in lines[i + 1:]:
                stripped = next_line.strip()

                # Skip separator lines (====) and blanks
                if not stripped or stripped.startswith("="):
                    continue

                return stripped

    raise Exception("SAS URL block found but no URL detected.")


def lambda_handler(event, context):
    print("Lambda triggered")

    response = s3.get_object(Bucket=BUCKET, Key=KEY)
    file_content = response["Body"].read().decode("utf-8")

    sas_url = extract_sas_url(file_content)

    secrets.put_secret_value(
        SecretId=SECRET_NAME,
        SecretString=sas_url
    )

    print("Secret successfully updated.")

    return {"status": "updated"}

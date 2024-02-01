import os
from datetime import datetime as dt
from urllib.error import HTTPError

import awswrangler as wr
import boto3
import pandas as pd
from notifications_python_client import prepare_upload
from notifications_python_client.notifications import NotificationsAPIClient


def handler(event, context):
    SECRET_ID = os.environ["SECRET_ID"]
    LOG_GROUP_NAMES = os.environ["LOG_GROUP_NAMES"]
    EMAIL_SECRET = os.environ["EMAIL_SECRET"]
    TEMPLATE_ID = os.environ["TEMPLATE_ID"]

    secrets_client = boto3.client("secretsmanager")

    secret_id = SECRET_ID.split("|")
    secret_arn = secret_id[0]
    secret_version = secret_id[1]

    response = secrets_client.get_secret_value(
        SecretId=secret_arn, VersionStage=secret_version
    )
    api_key = response["SecretString"]

    notifications_client = NotificationsAPIClient(api_key)

    email_id = EMAIL_SECRET.split("|")
    email_arn = email_id[0]
    email_version = email_id[1]
    response = secrets_client.get_secret_value(
        SecretId=email_arn, VersionStage=email_version
    )
    email_address = response["SecretString"]

    now = dt.now()
    current_date = dt.strftime(now.date(), "%Y/%m/%d")

    # Query
    query = f"""fields detail.data.user_id as `User`, detail.data.user_name as `Employee Email Address`
    | filter detail.data.type = "s"
    | filter detail.data.connection = "github"
    | stats max(@timestamp) as `Last login date` by "{current_date}" as `Effective Date of Data`, \
     `User`, `Employee Email Address`
    | sort `Last login date` desc
    """

    # Date range
    year = dt.now().year
    current_month = dt.now().month
    previous_month = current_month - 1
    end_datetime = dt(year, current_month, 1, 0, 0, 0)
    if previous_month == 0:
        previous_month = 12
        end_datetime = dt(year, current_month, 1, 0, 0, 0)
        year = year - 1

    start_datetime = dt(year, previous_month, 1, 0, 0, 0)

    # Read logs
    dataframe = wr.cloudwatch.read_logs(
        log_group_names=[LOG_GROUP_NAMES],
        query=query,
        start_time=start_datetime,
        end_time=end_datetime,
    )

    # Datestamp
    datestamp = end_datetime.strftime(format="%Y_%m_%d")
    dataframe["Last login date"] = pd.to_datetime(
        dataframe["Last login date"], format="%Y-%m-%d %H:%M:%S.%f"
    ).apply(lambda x: str(dt.strftime(x, "%Y/%m/%d")))

    # Save to Excel
    excel_filename = f"/tmp/jml_extract_{datestamp}.xlsx"
    dataframe.to_excel(excel_filename, index=False, sheet_name="Data")

    # Send email notification
    with open(excel_filename, "rb") as f:
        try:
            response = notifications_client.send_email_notification(
                email_address=email_address,
                template_id=TEMPLATE_ID,
                personalisation={
                    "date": current_date,
                    "link_to_file": prepare_upload(f),
                },
            )
        except HTTPError as e:
            print(e)
            raise e

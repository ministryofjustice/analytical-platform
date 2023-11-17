import boto3
from datetime import datetime as dt
import pandas as pd
import awswrangler as wr
from notifications_python_client.notifications import NotificationsAPIClient
from notifications_python_client import prepare_upload
from urllib.error import HTTPError

def handler(
    event,
    context,
):
    boto3.setup_default_session(region_name="eu-west-2")
    secrets_client = boto3.client('secretsmanager')
    response = client.get_secret_value(
        SecretId="gov-uk-notify/production/api-key",
    )
    api_key = response['SecretString']
    notifications_client = NotificationsAPIClient(api_key)

    now = dt.now()
    current_date = dt.strftime(now.date(), "%d/%m/%Y")

    query = f"""fields detail.data.user_id as user, detail.data.user_name as email
    | filter detail.data.type = "s"
    | filter detail.data.connection = "github"
    | stats max(@timestamp) as last_login by "{current_date}" as effective_date, user, email
    | sort last_login desc
    """
    year = dt.now().year
    current_month = dt.now().month
    previous_month = current_month - 1
    end_datetime = dt(year, current_month, 1, 0, 0, 0)
    if previous_month == 0:
        previous_month = 12
        year = year - 1
        end_datetime = dt(year, current_month, 1, 0, 0, 0)

    start_datetime = dt(year, previous_month, 1, 0, 0, 0)

    dataframe = wr.cloudwatch.read_logs(
        log_group_names=['/aws/events/auth0/alpha-analytics-moj'],
        query=query,
        start_time=start_datetime,
        end_time=end_datetime,
    )

    dataframe['last_login'] = pd.to_datetime(dataframe['last_login'], format="%Y-%m-%d %H:%M:%S.%f").apply(lambda x: str(dt.strftime(x, "%Y/%m/%d")))

    dataframe.to_excel('/tmp/test.xlsx', index=False)

    # client = boto3.client('s3')
    # client.upload_file('/tmp/test.xlsx', 'jml-export-bucket-REPLACE-ME', 'test.xlsx')
    with open('/tmp/test.xlsx', 'rb') as f:
        try:
            response = notifications_client.send_email_notification(
                email_address='CHANGE_ME@example.com',
                template_id='de618989-db86-4d9a-aa55-4724d5485fa5',
                personalisation={
                    'date': current_date,
                    'link_to_file': prepare_upload(f),
                }
            )
        except HTTPError as e:
            print(e)
            raise(e)


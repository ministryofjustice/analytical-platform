import os

from pdpyras import APISession
from slack_sdk import WebClient

pagerduty_scedule_id = os.environ["PAGERDUTY_SCHEDULE_ID"]
pagerduty_token = os.environ["PAGERDUTY_TOKEN"]

slack_token = os.environ["SLACK_TOKEN"]
slack_channel = os.environ["SLACK_CHANNEL"]

pagerduty_client = APISession(pagerduty_token)
slack_client = WebClient(token=slack_token)


def get_on_call_schedule_name():
    response = pagerduty_client.get('/schedules/' + pagerduty_scedule_id)

    if response.ok:
        schedule_name = response.json()['schedule']['name']

    return schedule_name

def get_on_call_user():
    response = pagerduty_client.get('/schedules/' + pagerduty_scedule_id + '/users?time_zone=Europe/London')
    user = None
    email = None

    if response.ok:
        user_name = response.json()['users'][0]['name']
        user_email = response.json()['users'][0]['email']

    return user_name, user_email

def get_slack_user():
    response = slack_client.users_lookupByEmail(email=get_on_call_user()[1])
    user_id = None
    display_name = None

    if response['ok']:
        user_id = response['user']['id']
        display_name = response['user']['profile']['display_name']

    return user_id, display_name

def main():
    slack_client.chat_postMessage(
        channel=slack_channel,
        text=f"Today's on-call engineer for {get_on_call_schedule_name()} is <@{get_slack_user()[0]}>",
    )


main()

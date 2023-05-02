import os
from time import strftime

from pdpyras import APISession
from slack_sdk import WebClient

date = strftime("%Y-%m-%d")

pagerduty_scedule_id = os.environ["PAGERDUTY_SCHEDULE_ID"]
pagerduty_token = os.environ["PAGERDUTY_TOKEN"]

slack_channel = os.environ["SLACK_CHANNEL"]
slack_token = os.environ["SLACK_TOKEN"]

pagerduty_client = APISession(pagerduty_token)
slack_client = WebClient(token=slack_token)


def get_on_call_schedule_name():
    response = pagerduty_client.get("/schedules/" + pagerduty_scedule_id)

    if response.ok:
        schedule_name = response.json()["schedule"]["name"]

    return schedule_name


def get_on_call_user():
    response = pagerduty_client.get(
        "/schedules/"
        + pagerduty_scedule_id
        + "/users?since="
        + date
        + "T09%3A00Z&until="
        + date
        + "T17%3A00Z"
    )
    user_name = None
    user_email = None

    if response.ok:
        user_name = response.json()["users"][0]["name"]
        user_email = response.json()["users"][0]["email"]

    return user_name, user_email


def get_slack_user_id():
    response = slack_client.users_lookupByEmail(email=get_on_call_user()[1])
    user_id = None

    if response["ok"]:
        user_id = response["user"]["id"]

    return user_id


def main():
    if get_slack_user_id() is None:
        message = f"Today's on-call engineer for {get_on_call_schedule_name()} is {get_on_call_user()[0]} (I can't match their email to a Slack user, sorry!)"  # noqa: E501
    else:
        message = f"Today's on-call engineer for {get_on_call_schedule_name()} is <@{get_slack_user_id()}>"

    slack_client.chat_postMessage(
        channel=slack_channel,
        text=message,
    )


main()

import authorizer
import pytest


@pytest.fixture(autouse=True)
def set_env_vars(monkeypatch):
    monkeypatch.setenv("api_resource_arn", "dummy-arn")
    monkeypatch.setenv("authorizationToken", "correct")
    monkeypatch.setenv("LOG_BUCKET", "log")


def test_valid_token(fake_context):
    response = authorizer.handler({"authorizationToken": "correct"}, fake_context)

    assert response == {
        "principalId": "abc123",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Resource": ["dummy-arn"],
                    "Effect": "Allow",
                }
            ],
        },
    }


def test_invalid_token(fake_context):
    response = authorizer.handler({"authorizationToken": "incorrect"}, fake_context)

    assert response == {
        "principalId": "abc123",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Resource": ["dummy-arn"],
                    "Effect": "Deny",
                }
            ],
        },
    }


def test_missing_token(fake_context):
    response = authorizer.handler({"authorizationToken": None}, fake_context)

    assert response == {
        "principalId": "abc123",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Resource": ["dummy-arn"],
                    "Effect": "Deny",
                }
            ],
        },
    }

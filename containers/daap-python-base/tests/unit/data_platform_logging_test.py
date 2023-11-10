import json
import os

import pytest
from data_platform_logging import DataPlatformLogger
from freezegun import freeze_time

extra_inputs = [
    {
        "data_product_name": "test_database",
        "table_name": "test_table",
        "image_version": "test",
        "base_image_version": "test",
    },
    {
        "table_name": "test_table",
        "image_version": "test",
        "base_image_version": "test",
    },
]


def setup_bucket(name, s3_client, region_name, monkeypatch):
    bucket_name = name
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    # Emulate the data product being set up in the bucket
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )


def setup_logger(extra_input):
    if "data_product_name" in extra_input.keys():
        test_logger = DataPlatformLogger(extra=extra_input)
    else:
        test_logger = DataPlatformLogger(
            data_product_name="test_database", extra=extra_input
        )
    return test_logger


@pytest.mark.parametrize("extra_input", extra_inputs)
@freeze_time("2023-01-01")
def test_stdout_info_log(extra_input, s3_client, region_name, capsys, monkeypatch):
    bucket_name = os.getenv("LOG_BUCKET", "")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)

    test_logger = setup_logger(extra_input)

    test_logger.info("test info message")
    captured = capsys.readouterr()
    event_info = json.loads(captured.out)

    assert event_info["message"] == "test info message"
    assert event_info["date_time"] == "2023-01-01 00:00:00"
    assert event_info["level"] == "info"
    assert set(extra_input.items()).issubset(set(event_info.items()))


@freeze_time("2023-01-01")
def test_stdout_warning_log(s3_client, region_name, capsys, monkeypatch):
    bucket_name = os.getenv("LOG_BUCKET", "")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)

    test_logger = DataPlatformLogger()
    test_logger.warning("test warning message")
    captured = capsys.readouterr()
    event_info = json.loads(captured.out)

    assert event_info["message"] == "test warning message"
    assert event_info["date_time"] == "2023-01-01 00:00:00"
    assert event_info["level"] == "warning"


@freeze_time("2023-01-01")
def test_stdout_debug_log(s3_client, region_name, capsys, monkeypatch):
    bucket_name = os.getenv("LOG_BUCKET", "")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)

    test_logger = DataPlatformLogger(level="DEBUG")
    test_logger.debug("test debug message")
    captured = capsys.readouterr()
    all_outputs = captured.out.split("\n")
    last_out = all_outputs[-2]
    event_info = json.loads(last_out)

    assert event_info["message"] == "test debug message"
    assert event_info["date_time"] == "2023-01-01 00:00:00"
    assert event_info["level"] == "debug"


@freeze_time("2023-01-01")
def test_stdout_error_log(s3_client, region_name, capsys, monkeypatch):
    bucket_name = os.getenv("LOG_BUCKET", "")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)

    test_logger = DataPlatformLogger()
    test_logger.error("test error message")
    captured = capsys.readouterr()
    event_info = json.loads(captured.out)

    assert event_info["message"] == "test error message"
    assert event_info["date_time"] == "2023-01-01 00:00:00"
    assert event_info["level"] == "error"


@pytest.mark.parametrize("extra_input", extra_inputs)
@freeze_time("2023-01-01")
def test__write_log_dict_to_json_s3(extra_input, s3_client, region_name, monkeypatch):
    expected_log_json = [
        {
            "level": "info",
            "date_time": "2023-01-01 00:00:00",
            "message": "test message 1",
            "function_name": "test__write_log_dict_to_json_s3",
            "lambda_name": "test_lambda",
            "data_product_name": "test_database",
            "table_name": "test_table",
            "image_version": "test",
            "base_image_version": "test",
        },
        {
            "level": "info",
            "date_time": "2023-01-01 00:00:00",
            "message": "test message 2",
            "function_name": "test__write_log_dict_to_json_s3",
            "lambda_name": "test_lambda",
            "data_product_name": "test_database",
            "table_name": "test_table",
            "image_version": "test",
            "base_image_version": "test",
        },
    ]
    bucket_name = os.getenv("LOG_BUCKET", "")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)

    test_logger = setup_logger(extra_input)

    test_logger.info("test message 1")
    test_logger.info("test message 2")

    response = s3_client.get_object(
        Bucket=bucket_name, Key=test_logger.log_bucket_path.key
    )
    data = response.get("Body").read().decode("utf-8")
    json_list = [json.loads(j) for j in data.split("\n") if j != ""]

    assert expected_log_json == json_list

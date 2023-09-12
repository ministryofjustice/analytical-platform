import json
from freezegun import freeze_time

from data_platform_logging import _make_log_dict, DataPlatformLogger


extra_input = {
    "lambda_name": "test_lambda",
    "data_product_name": "test_database",
    "table_name": "test_table",
    "image_version": "test",
    "base_image_version": "test",
}


@freeze_time("2023-01-01")
def test__make_log_dict():
    expected_result = {
        "level": "debug",
        "date_time": "2023-01-01 00:00:00",
        "message": "just a test message",
        "function_name": "test_function",
        "image_version": "test",
        "base_image_version": "test",
        "lambda_name": "test_lambda",
        "data_product_name": "test_database",
        "table_name": "test_table",
    }

    test_result = _make_log_dict(
        level="debug",
        msg="just a test message",
        extra=extra_input,
        func="test_function",
    )

    assert test_result == expected_result


@freeze_time("2023-01-01")
def test_stdout_info_log(s3_client, region_name, capsys, monkeypatch):
    bucket_name = "bucket"
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    # Emulate the data product being set up in the bucket
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )

    test_logger = DataPlatformLogger(extra=extra_input)
    test_logger.info("test info message")
    captured = capsys.readouterr()
    assert "INFO     | 2023-01-01 00:00:00 | test info message\n" == captured.out


@freeze_time("2023-01-01")
def test_stdout_warning_log(s3_client, region_name, capsys, monkeypatch):
    bucket_name = "bucket"
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    # Emulate the data product being set up in the bucket
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )

    test_logger = DataPlatformLogger()
    test_logger.warning("test warning message")
    captured = capsys.readouterr()
    assert "WARNING  | 2023-01-01 00:00:00 | test warning message\n" == captured.out


@freeze_time("2023-01-01")
def test_stdout_debug_log(s3_client, region_name, capsys, monkeypatch):
    bucket_name = "bucket"
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    # Emulate the data product being set up in the bucket
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )

    test_logger = DataPlatformLogger(level="DEBUG")
    test_logger.debug("test debug message")
    captured = capsys.readouterr()
    all_outputs = captured.out.split("\n")
    last_out = all_outputs[-2]
    assert "DEBUG    | 2023-01-01 00:00:00 | test debug message" == last_out


@freeze_time("2023-01-01")
def test_stdout_error_log(s3_client, region_name, capsys, monkeypatch):
    bucket_name = "bucket"
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    # Emulate the data product being set up in the bucket
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )

    test_logger = DataPlatformLogger()
    test_logger.error("test error message")
    captured = capsys.readouterr()
    assert "ERROR    | 2023-01-01 00:00:00 | test error message\n" == captured.out


@freeze_time("2023-01-01")
def test__write_log_dict_to_json_s3(s3_client, region_name, monkeypatch):
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
    bucket_name = "bucket"
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    # Emulate the data product being set up in the bucket
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )

    test_logger = DataPlatformLogger(extra=extra_input)

    test_logger.info("test message 1")
    test_logger.info("test message 2")

    response = s3_client.get_object(
        Bucket=bucket_name, Key=test_logger.log_bucket_path.key
    )
    data = response.get("Body").read().decode("utf-8")
    json_list = [json.loads(j) for j in data.split("\n") if j != ""]

    assert expected_log_json == json_list

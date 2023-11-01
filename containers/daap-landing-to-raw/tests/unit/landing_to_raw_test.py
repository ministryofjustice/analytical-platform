from unittest.mock import patch

import pytest
from botocore.exceptions import ClientError
from landing_to_raw import extract_columns_from_schema, handler


class TestHandler:
    @pytest.fixture
    def destination_bucket(self):
        return "test"

    @pytest.fixture
    def landing_bucket(self):
        return "landing"

    @pytest.fixture(autouse=True)
    def setup_buckets(
        self, s3_client, destination_bucket, landing_bucket, autouse=True
    ):
        with patch("landing_to_raw.s3", s3_client):
            s3_client.create_bucket(Bucket=landing_bucket)
            s3_client.create_bucket(Bucket=destination_bucket)
            yield

    @pytest.fixture(autouse=True)
    def setup_registered_schema(self):
        result = {
            "TableInput": {
                "StorageDescriptor": {
                    "Columns": [
                        {"Name": "a", "Type": "string"},
                        {"Name": "b", "Type": "integer"},
                        {"Name": "c", "Type": "integer"},
                    ]
                }
            }
        }

        with patch("landing_to_raw.read_json_from_s3") as f:
            f.return_value = result
            yield

    def test_valid_file(
        self, s3_client, destination_bucket, landing_bucket, fake_context
    ):
        test_event = {
            "detail": {
                "bucket": {"name": landing_bucket},
                "object": {
                    "key": "landing/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv"
                },
            }
        }

        s3_client.put_object(
            Key=test_event["detail"]["object"]["key"],
            Bucket=test_event["detail"]["bucket"]["name"],
            Body="a,b,c\n1,2,3\n4,5,6",
        )
        handler(test_event, fake_context)

        assert s3_client.get_object(
            Key="raw/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv",
            Bucket=destination_bucket,
        )

        with pytest.raises(ClientError):
            s3_client.get_object(
                Key="fail/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv",
                Bucket=destination_bucket,
            )

        with pytest.raises(ClientError):
            s3_client.get_object(
                Key="landing/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv",
                Bucket=landing_bucket,
            )

    def test_invalid_file(
        self, s3_client, destination_bucket, landing_bucket, fake_context
    ):
        test_event = {
            "detail": {
                "bucket": {"name": landing_bucket},
                "object": {
                    "key": "landing/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv"
                },
            }
        }

        s3_client.put_object(
            Key=test_event["detail"]["object"]["key"],
            Bucket=test_event["detail"]["bucket"]["name"],
            Body="d,b,c\n1,2,3\n4,5,6",
        )
        handler(test_event, fake_context)

        assert s3_client.get_object(
            Key="fail/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv",
            Bucket=destination_bucket,
        )

        with pytest.raises(ClientError):
            s3_client.get_object(
                Key="raw/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv",
                Bucket=destination_bucket,
            )

    def test_valid_schema_but_newlines_in_column(
        self, s3_client, destination_bucket, landing_bucket, fake_context
    ):
        test_event = {
            "detail": {
                "bucket": {"name": landing_bucket},
                "object": {
                    "key": "landing/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv"
                },
            }
        }

        s3_client.put_object(
            Key=test_event["detail"]["object"]["key"],
            Bucket=test_event["detail"]["bucket"]["name"],
            Body='a,b,c\n1,2,3\n"this\nis\na\nmulti\nline\nvalue",5,6',
        )
        handler(test_event, fake_context)

        assert s3_client.get_object(
            Key="fail/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv",
            Bucket=destination_bucket,
        )

        with pytest.raises(ClientError):
            s3_client.get_object(
                Key="raw/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv",
                Bucket=destination_bucket,
            )


class TestExtractColumnsFromSchema:
    def test_valid(self):
        columns = extract_columns_from_schema(
            {
                "TableInput": {
                    "StorageDescriptor": {
                        "Columns": [
                            {"Name": "foo", "Type": "string"},
                            {"Name": "bar", "Type": "int"},
                        ]
                    }
                }
            }
        )

        assert columns == {"foo": "string", "bar": "int"}

    def test_invalid(self):
        with pytest.raises(ValueError):
            extract_columns_from_schema({})

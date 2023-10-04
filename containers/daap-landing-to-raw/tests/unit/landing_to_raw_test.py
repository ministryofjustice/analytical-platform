from unittest.mock import patch

import pytest
from botocore.exceptions import ClientError
from landing_to_raw import (
    DataInvalid,
    extract_columns_from_schema,
    handler,
    type_is_compatable,
    validate_data_against_schema,
)


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
                        {"Name": "a", "Type": "integer"},
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


@pytest.mark.parametrize(
    "registered_type,inferred_type,expected",
    [
        ("tinyint", "tinyint", True),
        ("smallint", "smallint", True),
        ("integer", "integer", True),
        ("int", "int", True),
        ("bigint", "bigint", True),
        ("float", "float", True),
        ("double", "double", True),
        ("decimal", "decimal", True),
        ("string", "string", True),
        ("boolean", "boolean", True),
        ("char", "char", True),
        ("timestamp", "timestamp", True),
        ("date", "date", True),
        ("array", "array", True),
        ("struct", "struct", True),
        ("garbage", "int", False),
        ("int", "garbage", False),
        ("tinyint", "smallint", True),
        ("tinyint", "int", True),
        ("tinyint", "bigint", True),
        ("tinyint", "float", False),
        ("tinyint", "double", False),
        ("tinyint", "decimal", False),
        ("tinyint", "string", False),
        ("tinyint", "boolean", False),
        ("tinyint", "timestamp", False),
        ("tinyint", "date", False),
        ("smallint", "tinyint", True),
        ("smallint", "int", True),
        ("smallint", "bigint", True),
        ("smallint", "float", False),
        ("smallint", "double", False),
        ("smallint", "decimal", False),
        ("smallint", "string", False),
        ("smallint", "boolean", False),
        ("smallint", "timestamp", False),
        ("smallint", "date", False),
        ("int", "tinyint", True),
        ("int", "smallint", True),
        ("int", "bigint", True),
        ("int", "float", False),
        ("int", "double", False),
        ("int", "decimal", False),
        ("int", "string", False),
        ("int", "boolean", False),
        ("int", "timestamp", False),
        ("int", "date", False),
        ("bigint", "tinyint", True),
        ("bigint", "smallint", True),
        ("bigint", "int", True),
        ("bigint", "float", False),
        ("bigint", "double", False),
        ("bigint", "decimal", False),
        ("bigint", "string", False),
        ("bigint", "boolean", False),
        ("bigint", "timestamp", False),
        ("bigint", "date", False),
        ("float", "tinyint", True),
        ("float", "smallint", True),
        ("float", "int", True),
        ("float", "bigint", True),
        ("float", "double", True),
        ("float", "decimal", True),
        ("float", "string", False),
        ("float", "boolean", False),
        ("float", "timestamp", False),
        ("float", "date", False),
        ("double", "tinyint", True),
        ("double", "smallint", True),
        ("double", "int", True),
        ("double", "bigint", True),
        ("double", "double", True),
        ("double", "decimal", True),
        ("double", "string", False),
        ("double", "boolean", False),
        ("double", "timestamp", False),
        ("double", "date", False),
        ("decimal", "tinyint", True),
        ("decimal", "smallint", True),
        ("decimal", "int", True),
        ("decimal", "bigint", True),
        ("decimal", "float", True),
        ("decimal", "double", True),
        ("decimal", "string", False),
        ("decimal", "boolean", False),
        ("decimal", "timestamp", False),
        ("decimal", "date", False),
        ("string", "tinyint", True),
        ("string", "smallint", True),
        ("string", "int", True),
        ("string", "bigint", True),
        ("string", "float", True),
        ("string", "double", True),
        ("string", "decimal", True),
        ("string", "boolean", True),
        ("string", "timestamp", True),
        ("string", "date", True),
        ("boolean", "tinyint", False),
        ("boolean", "smallint", False),
        ("boolean", "int", False),
        ("boolean", "bigint", False),
        ("boolean", "float", False),
        ("boolean", "double", False),
        ("boolean", "decimal", False),
        ("boolean", "string", False),
        ("boolean", "timestamp", False),
        ("boolean", "date", False),
        ("timestamp", "tinyint", False),
        ("timestamp", "smallint", False),
        ("timestamp", "int", False),
        ("timestamp", "bigint", False),
        ("timestamp", "float", False),
        ("timestamp", "double", False),
        ("timestamp", "decimal", False),
        ("timestamp", "boolean", False),
        ("date", "tinyint", False),
        ("date", "smallint", False),
        ("date", "int", False),
        ("date", "bigint", False),
        ("date", "double", False),
        ("date", "float", False),
        ("date", "decimal", False),
        ("date", "boolean", False),
        ("date", "timestamp", False),
    ],
)
def test_type_is_compatable(registered_type, inferred_type, expected):
    assert (
        type_is_compatable(registered_type=registered_type, inferred_type=inferred_type)
        == expected
    )


class TestValidateAgainstSchema:
    @pytest.fixture
    def schema(self):
        return {"foo": "string", "bar": "int", "baz": "timestamp"}

    def test_valid_match(self, schema):
        validate_data_against_schema(
            registered_schema_columns=schema, inferred_columns=schema
        )

    def test_lenient_match(self, schema):
        validate_data_against_schema(
            registered_schema_columns=schema,
            inferred_columns={"foo": "int", "bar": "smallint", "baz": "date"},
        )

    def test_missing_columns(self, schema):
        with pytest.raises(DataInvalid):
            validate_data_against_schema(
                registered_schema_columns=schema,
                inferred_columns={"foo": "int", "bar": "smallint"},
            )

    def test_extra_columns(self, schema):
        with pytest.raises(DataInvalid):
            validate_data_against_schema(
                registered_schema_columns=schema,
                inferred_columns=dict(**schema, extra="integer"),
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

from unittest.mock import patch
import pytest

from landing_to_raw import handler, type_is_compatable


def test_handler(s3_client, fake_context):
    test_event = {
        "detail": {
            "bucket": {"name": "landing"},
            "object": {
                "key": "landing/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv"
            },
        }
    }
    destination_bucket = "test"

    with patch("landing_to_raw.s3", s3_client):
        s3_client.create_bucket(Bucket=test_event["detail"]["bucket"]["name"])
        s3_client.create_bucket(Bucket=destination_bucket)
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

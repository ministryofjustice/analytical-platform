import json

import pytest
from get_schema import handler


class TestHandler:
    @pytest.fixture
    def data_product_name(self):
        return "data-product"

    @pytest.fixture
    def table_name(self):
        return "table-name"

    @pytest.fixture
    def schema(self):
        return {"hello": "world"}

    @pytest.fixture(autouse=True)
    def setup_metadata_bucket(
        self, s3_client, data_product_name, table_name, schema, monkeypatch
    ):
        monkeypatch.setenv("METADATA_BUCKET", "metadata")

        s3_client.create_bucket(Bucket="metadata")
        s3_client.put_object(
            Bucket="metadata",
            Key=f"{data_product_name}/v1.0/{table_name}/schema.json",
            Body=json.dumps(schema),
        )

    def test_valid(self, fake_context, data_product_name, table_name, schema):
        result = handler(
            {
                "pathParameters": {
                    "data-product-name": data_product_name,
                    "table-name": table_name,
                }
            },
            fake_context,
        )

        assert result == {
            "body": json.dumps(schema),
            "headers": {"Content-Type": "application/json"},
            "statusCode": 200,
        }

    def test_missing(self, fake_context):
        result = handler(
            {
                "pathParameters": {
                    "data-product-name": "abc",
                    "table-name": "def",
                }
            },
            fake_context,
        )

        assert result == {
            "body": json.dumps(
                {
                    "error": {
                        "message": "Schema not found for data product 'abc', table 'def'"
                    }
                }
            ),
            "headers": {"Content-Type": "application/json"},
            "statusCode": 404,
        }

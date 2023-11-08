import json
from http import HTTPStatus
from unittest.mock import patch

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
    def glue_schema(self):
        return {"hello": "world"}

    @pytest.fixture
    def out_schema(self):
        return {"goodbye": "world"}

    @pytest.fixture(autouse=True)
    def setup_metadata_bucket(
        self, s3_client, data_product_name, table_name, glue_schema, monkeypatch
    ):
        monkeypatch.setenv("METADATA_BUCKET", "metadata")

        s3_client.create_bucket(Bucket="metadata")
        s3_client.put_object(
            Bucket="metadata",
            Key=f"{data_product_name}/v1.0/{table_name}/schema.json",
            Body=json.dumps(glue_schema),
        )

    def test_valid(
        self,
        fake_context,
        data_product_name,
        table_name,
        out_schema,
    ):
        with patch("get_schema.format_table_schema", return_value=out_schema):
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
                "body": json.dumps(out_schema),
                "headers": {"Content-Type": "application/json"},
                "statusCode": HTTPStatus.OK,
            }

    def test_missing(self, fake_context):
        data_product_name = "abc"
        table_name = "def"

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
            "body": json.dumps(
                {
                    "error": {
                        "message": f"no existing table schema found in S3 for {table_name=} {data_product_name=}"
                    }
                }
            ),
            "headers": {"Content-Type": "application/json"},
            "statusCode": HTTPStatus.NOT_FOUND,
        }

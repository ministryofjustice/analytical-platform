import pytest
from data_platform_catalogue.entities import DataProductMetadata, TableMetadata


@pytest.fixture
def data_product():
    return DataProductMetadata(
        name="my_data_product",
        description="bla bla",
        version="v1.0.0",
        owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
        email="justice@justice.gov.uk",
        retention_period_in_days=365,
        domain="legal-aid",
        dpia_required=False,
        tags=["test"],
    )


@pytest.fixture
def table():
    return TableMetadata(
        name="my_table",
        description="bla bla",
        column_details=[
            {"name": "foo", "type": "string", "description": "a"},
            {"name": "bar", "type": "int", "description": "b"},
        ],
        retention_period_in_days=None,
        tags=["test"],
    )


def test_from_data_product_metadata_dict(data_product):
    data_product2 = DataProductMetadata.from_data_product_metadata_dict(
        {
            "name": "my_data_product",
            "description": "bla bla",
            "domain": "legal-aid",
            "dataProductOwner": "justice@justice.gov.uk",
            "dataProductOwnerDisplayName": "justice",
            "email": "justice@justice.gov.uk",
            "status": "draft",
            "dpiaRequired": False,
            "retentionPeriod": 365,
            "tags": ["test"],
        },
        "v1.0.0",
        "2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
    )
    assert data_product2 == data_product


def test_from_data_product_schema_dict(table):
    table2 = TableMetadata.from_data_product_schema_dict(
        {
            "tableDescription": "bla bla",
            "columns": [
                {"name": "foo", "type": "string", "description": "a"},
                {"name": "bar", "type": "int", "description": "b"},
            ],
            "tags": ["test"],
        },
        "my_table",
    )

    assert table2 == table

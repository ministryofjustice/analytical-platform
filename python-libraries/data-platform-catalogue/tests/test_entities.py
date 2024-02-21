from datetime import datetime

import pytest
from data_platform_catalogue.entities import (
    DataProductMetadata,
    DataProductStatus,
    SecurityClassification,
    TableMetadata,
)


@pytest.fixture
def data_product():
    return DataProductMetadata(
        name="my_data_product",
        description="bla bla",
        version="v1.0.0",
        owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
        owner_display_name="April Gonzalez",
        maintainer="j.shelvey@digital.justice.gov.uk",
        maintainer_display_name="Jonjo Shelvey",
        email="justice@justice.gov.uk",
        status=DataProductStatus.DRAFT,
        retention_period_in_days=365,
        domain="LAA",
        subdomain="Legal Aid",
        dpia_required=False,
        dpia_location=None,
        last_updated=datetime(2020, 5, 17),
        creation_date=datetime(2020, 5, 17),
        s3_location="s3://databucket/",
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
        source_dataset_name="my_source_table",
        where_to_access_dataset="s3://source-bucket/folder",
        data_sensitivity_level=SecurityClassification.OFFICIAL,
        tags=["test"],
    )


def test_from_data_product_metadata_dict(data_product):
    data_product2 = DataProductMetadata.from_data_product_metadata_dict(
        {
            "name": "my_data_product",
            "description": "bla bla",
            "domain": "LAA",
            "subdomain": "Legal Aid",
            "dataProductOwner": "justice@justice.gov.uk",
            "dataProductOwnerDisplayName": "April Gonzalez",
            "dataProductMaintainer": "j.shelvey@digital.justice.gov.uk",
            "dataProductMaintainerDisplayName": "Jonjo Shelvey",
            "email": "justice@justice.gov.uk",
            "status": "DRAFT",
            "dpiaRequired": False,
            "retentionPeriod": 365,
            "lastUpdated": "20200517",
            "creationDate": "20200517",
            "s3Location": "s3://databucket/",
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
            "sourceDatasetName": "my_source_table",
            "sourceDatasetLocation": "s3://source-bucket/folder",
        },
        "my_table",
    )

    assert table2 == table

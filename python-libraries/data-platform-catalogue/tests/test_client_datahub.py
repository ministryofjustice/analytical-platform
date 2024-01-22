from pathlib import Path

import pytest
from data_platform_catalogue.client import DataHubCatalogueClient
from data_platform_catalogue.entities import (
    CatalogueMetadata,
    DataLocation,
    DataProductMetadata,
    TableMetadata,
)


class TestCatalogueClientWithDatahub:
    """
    Test that the contract with DataHubGraph has not changed, using a mock.

    If this is the case, then the final metadata graph should match a snapshot we took earlier.
    """

    @pytest.fixture
    def catalogue(self):
        return CatalogueMetadata(
            name="data_platform",
            description="All data products hosted on the data platform",
            owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
        )

    @pytest.fixture
    def data_product(self):
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
    def table(self):
        return TableMetadata(
            name="my_table",
            description="bla bla",
            column_details=[
                {"name": "foo", "type": "string", "description": "a"},
                {"name": "bar", "type": "int", "description": "b"},
            ],
            retention_period_in_days=365,
        )

    @pytest.fixture
    def datahub_client(self, base_mock_graph) -> DataHubCatalogueClient:
        return DataHubCatalogueClient(
            jwt_token="abc", api_url="http://example.com/api/gms", graph=base_mock_graph
        )

    def test_create_table_datahub(
        self, datahub_client, base_mock_graph, table, tmp_path, check_snapshot
    ):
        """
        Case where we just create a dataset (no data product)
        """
        fqn = datahub_client.upsert_table(
            metadata=table,
            location=DataLocation(fully_qualified_name="my_database"),
        )
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:glue,my_database.my_table,PROD)"

        assert fqn == fqn_out

        output_file = Path(tmp_path / "datahub_create_table.json")
        base_mock_graph.sink_to_file(output_file)
        check_snapshot("datahub_create_table.json", output_file)

    def test_create_table_with_metadata_datahub(
        self,
        datahub_client,
        table,
        data_product,
        base_mock_graph,
        tmp_path,
        check_snapshot,
    ):
        """
        Case where we create a dataset, data product and domain
        """
        fqn = datahub_client.upsert_table(
            metadata=table,
            data_product_metadata=data_product,
            location=DataLocation("my_database"),
        )
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:glue,my_database.my_table,PROD)"

        assert fqn == fqn_out

        output_file = Path(tmp_path / "datahub_create_table_with_metadata.json")
        base_mock_graph.sink_to_file(output_file)
        check_snapshot("datahub_create_table_with_metadata.json", output_file)

    def test_create_table_and_metadata_idempotent_datahub(
        self,
        datahub_client,
        table,
        data_product,
        base_mock_graph,
        tmp_path,
        check_snapshot,
    ):
        """
        `create_table` should work even if the entities already exist in the metadata graph.
        """
        datahub_client.upsert_table(
            metadata=table,
            data_product_metadata=data_product,
            location=DataLocation("my_database"),
        )

        fqn = datahub_client.upsert_table(
            metadata=table,
            data_product_metadata=data_product,
            location=DataLocation("my_database"),
        )
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:glue,my_database.my_table,PROD)"

        assert fqn == fqn_out

        output_file = Path(tmp_path / "datahub_create_table_with_metadata.json")
        base_mock_graph.sink_to_file(output_file)
        check_snapshot("datahub_create_table_with_metadata.json", output_file)

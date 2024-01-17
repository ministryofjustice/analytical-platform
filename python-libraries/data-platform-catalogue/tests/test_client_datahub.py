from pathlib import Path

import pytest
from data_platform_catalogue.client import DataHubCatalogueClient
from data_platform_catalogue.entities import (
    CatalogueMetadata,
    DataProductMetadata,
    TableMetadata,
)
from tests.test_helpers.mce_helpers import check_golden_file


class TestCatalogueClientWithDatahub:
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
        self,
        datahub_client,
        base_mock_graph,
        table,
        tmp_path,
        test_snapshots_dir,
        pytestconfig,
    ):
        """
        Test that the contract with DataHubGraph has not changed, using a mock.

        If so, then the final metadata graph should match the snapshot in snapshots/datahub_create_table.json.
        """
        fqn = datahub_client.upsert_table(metadata=table)
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:glue,my_table,PROD)"

        assert fqn == fqn_out

        output_file = Path(tmp_path / "datahub_create_table.json")
        base_mock_graph.sink_to_file(output_file)
        last_snapshot = Path(test_snapshots_dir / "datahub_create_table.json")
        check_golden_file(pytestconfig, output_file, last_snapshot)

    def test_create_table_with_metadata_datahub(
        self,
        datahub_client,
        table,
        data_product,
        base_mock_graph,
        tmp_path,
        test_snapshots_dir,
        pytestconfig,
    ):
        """
        Test that the contract with DataHubGraph has not changed, using a mock.

        If so, then the final metadata graph should match the snapshot in
        snapshots/datahub_create_table_with_metadata.json.

        This version of the method upserts the domain, data product and table in one step.
        """
        fqn = datahub_client.upsert_table(
            metadata=table, data_product_metadata=data_product
        )
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:glue,my_table,PROD)"

        assert fqn == fqn_out

        output_file = Path(tmp_path / "datahub_create_table.json")
        base_mock_graph.sink_to_file(output_file)
        last_snapshot = Path(
            test_snapshots_dir / "datahub_create_table_with_metadata.json"
        )
        check_golden_file(pytestconfig, output_file, last_snapshot)

    def test_create_table_and_metadata_idempotent_datahub(
        self,
        datahub_client,
        table,
        data_product,
        base_mock_graph,
        tmp_path,
        test_snapshots_dir,
        pytestconfig,
    ):
        """
        Test that the contract with DataHubGraph has not changed, using a mock.

        If so, then the final metadata graph should match the snapshot in
        snapshots/datahub_create_table_with_metadata.json.

        This should work even if the entities already exist in the metadata graph.
        """
        datahub_client.upsert_table(metadata=table, data_product_metadata=data_product)

        fqn = datahub_client.upsert_table(
            metadata=table, data_product_metadata=data_product
        )
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:glue,my_table,PROD)"

        assert fqn == fqn_out

        output_file = Path(tmp_path / "datahub_create_table.json")
        base_mock_graph.sink_to_file(output_file)
        last_snapshot = Path(
            test_snapshots_dir / "datahub_create_table_with_metadata.json"
        )
        check_golden_file(pytestconfig, output_file, last_snapshot)

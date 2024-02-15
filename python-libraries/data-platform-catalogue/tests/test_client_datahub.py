from datetime import datetime
from pathlib import Path

import pytest
from data_platform_catalogue.client.datahub.datahub_client import DataHubCatalogueClient
from data_platform_catalogue.entities import (
    CatalogueMetadata,
    DataLocation,
    DataProductMetadata,
    DataProductStatus,
    SecurityClassification,
    TableMetadata,
)
from datahub.metadata.schema_classes import DataProductPropertiesClass


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
    def table(self):
        return TableMetadata(
            name="my_table",
            description="bla bla",
            column_details=[
                {"name": "foo", "type": "string", "description": "a"},
                {"name": "bar", "type": "int", "description": "b"},
            ],
            retention_period_in_days=365,
            source_dataset_name="my_source_table",
            where_to_access_dataset="s3://databucket/table1",
            data_sensitivity_level=SecurityClassification.TOP_SECRET,
        )

    @pytest.fixture
    def table2(self):
        return TableMetadata(
            name="my_table2",
            description="this is a different table",
            column_details=[
                {"name": "boo", "type": "boolean", "description": "spooky"},
                {"name": "yar", "type": "string", "description": "shiver my timbers"},
            ],
            retention_period_in_days=1,
            source_dataset_name="my_source_table",
            where_to_access_dataset="s3://databucket/table2",
            data_sensitivity_level=SecurityClassification.OFFICIAL,
        )

    @pytest.fixture
    def datahub_client(self, base_mock_graph) -> DataHubCatalogueClient:
        return DataHubCatalogueClient(
            jwt_token="abc", api_url="http://example.com/api/gms", graph=base_mock_graph
        )

    @pytest.fixture
    def golden_file_in(self):
        return Path(
            Path(__file__).parent / "test_resources/golden_data_product_in.json"
        )

    def test_create_table_datahub(
        self,
        datahub_client,
        base_mock_graph,
        table,
        tmp_path,
        check_snapshot,
        golden_file_in,
    ):
        """
        Case where we just create a dataset (no data product)
        """
        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in)

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
        golden_file_in,
    ):
        """
        Case where we create a dataset, data product and domain
        """
        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in)

        fqn = datahub_client.upsert_table(
            metadata=table,
            data_product_metadata=data_product,
            location=DataLocation("my_database"),
        )
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:glue,my_database.my_table,PROD)"

        assert fqn == fqn_out

        # check data product properties persist
        dp_properties = mock_graph.get_aspect(
            "urn:li:dataProduct:my_data_product", aspect_type=DataProductPropertiesClass
        )
        assert dp_properties.description == "bla bla"
        assert dp_properties.customProperties == {"version": "2.0", "dpia": "false"}
        output_file = Path(tmp_path / "datahub_create_table_with_metadata.json")
        base_mock_graph.sink_to_file(output_file)
        check_snapshot("datahub_create_table_with_metadata.json", output_file)

    def test_create_two_tables_with_metadata(
        self,
        datahub_client,
        table,
        table2,
        data_product,
        base_mock_graph,
        tmp_path,
        check_snapshot,
        golden_file_in,
    ):
        """
        Case where we create a dataset, data product and domain
        """

        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in)

        fqn = datahub_client.upsert_table(
            metadata=table,
            data_product_metadata=data_product,
            location=DataLocation("my_database"),
        )
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:glue,my_database.my_table,PROD)"

        assert fqn == fqn_out

        fqn = datahub_client.upsert_table(
            metadata=table2,
            data_product_metadata=data_product,
            location=DataLocation("my_database"),
        )
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:glue,my_database.my_table2,PROD)"

        assert fqn == fqn_out

        output_file = Path(tmp_path / "datahub_create_table_with_metadata.json")
        base_mock_graph.sink_to_file(output_file)
        check_snapshot("datahub_create_two_tables_with_metadata.json", output_file)

    def test_create_table_and_metadata_idempotent_datahub(
        self,
        datahub_client,
        table,
        data_product,
        base_mock_graph,
        tmp_path,
        check_snapshot,
        golden_file_in,
    ):
        """
        `create_table` should work even if the entities already exist in the metadata graph.
        """
        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in)

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

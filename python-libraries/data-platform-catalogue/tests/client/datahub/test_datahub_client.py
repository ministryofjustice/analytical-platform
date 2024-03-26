from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from data_platform_catalogue.client.datahub.datahub_client import (
    DataHubCatalogueClient,
    InvalidDomain,
    MissingDatabaseMetadata,
)
from data_platform_catalogue.entities import (
    CatalogueMetadata,
    ChartMetadata,
    DatabaseMetadata,
    DatabaseStatus,
    DataLocation,
    DataProductMetadata,
    DataProductStatus,
    RelatedEntity,
    RelationshipType,
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
    def database(self):
        return DatabaseMetadata(
            name="my_database",
            description="little test db",
            version="v1.0.0",
            owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
            owner_display_name="April Gonzalez",
            maintainer="j.shelvey@digital.justice.gov.uk",
            maintainer_display_name="Jonjo Shelvey",
            email="justice@justice.gov.uk",
            status=DatabaseStatus.PROD.name,
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
            data_sensitivity_level=SecurityClassification.OFFICIAL,
            parent_entity_name="my_database",
            domain="LAA",
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
    def golden_file_in_dp(self):
        return Path(
            Path(__file__).parent / "../../test_resources/golden_data_product_in.json"
        )

    @pytest.fixture
    def golden_file_in_db(self):
        return Path(
            Path(__file__).parent / "../../test_resources/golden_database_in.json"
        )

    def test_create_table_datahub(
        self,
        datahub_client,
        base_mock_graph,
        table,
        tmp_path,
        check_snapshot,
        golden_file_in_dp,
    ):
        """
        Case where we just create a dataset (no data product)
        """
        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in_dp)

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
        golden_file_in_dp,
    ):
        """
        Case where we create a dataset, data product and domain
        """
        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in_dp)

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
        golden_file_in_dp,
    ):
        """
        Case where we create a dataset, data product and domain
        """

        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in_dp)

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
        golden_file_in_dp,
    ):
        """
        `create_table` should work even if the entities already exist in the metadata graph.
        """
        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in_dp)

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

    def test_get_dataset(
        self,
        datahub_client,
        base_mock_graph,
    ):
        urn = "abc"
        datahub_response = {
            "dataset": {
                "platform": {"name": "datahub"},
                "ownership": None,
                "subTypes": None,
                "container_relations": {
                    "total": 1,
                    "relationships": [
                        {
                            "entity": {
                                "urn": "urn:li:container:databse",
                                "properties": {"name": "database"},
                            }
                        }
                    ],
                },
                "data_product_relations": {"total": 0, "relationships": []},
                "name": "Dataset",
                "properties": {
                    "name": "Dataset",
                    "qualifiedName": "Foo.Dataset",
                    "description": "Dataset",
                    "customProperties": [
                        {"key": "sensitivityLevel", "value": "OFFICIAL-SENSITIVE"}
                    ],
                    "lastModified": 1709619407814,
                },
                "editableProperties": None,
                "tags": {
                    "tags": [
                        {
                            "tag": {
                                "urn": "urn:li:tag:Entity",
                                "properties": {"name": "some-tag"},
                            }
                        }
                    ]
                },
                "lastIngested": 1709619407814,
                "domain": None,
                "schemaMetadata": {
                    "fields": [
                        {
                            "fieldPath": "urn",
                            "label": None,
                            "nullable": False,
                            "description": "The primary identifier for the dataset entity.",
                            "type": "STRING",
                            "nativeDataType": "string",
                        },
                        {
                            "fieldPath": "upstreamLineage",
                            "label": None,
                            "nullable": False,
                            "description": "Upstream lineage of a dataset",
                            "type": "STRUCT",
                            "nativeDataType": "upstreamLineage",
                        },
                    ],
                    "primaryKeys": ["urn"],
                    "foreignKeys": [
                        {
                            "name": "DownstreamOf",
                            "foreignFields": [{"fieldPath": "urn"}],
                            "foreignDataset": {
                                "urn": "urn:li:dataset:(urn:li:dataPlatform:datahub,Dataset,PROD)",
                                "properties": {
                                    "name": "Dataset",
                                    "qualifiedName": None,
                                },
                            },
                            "sourceFields": [{"fieldPath": "upstreamLineage"}],
                        },
                    ],
                },
            }
        }
        base_mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

        dataset = datahub_client.get_table_details(urn)

        assert dataset == TableMetadata(
            name="Dataset",
            description="Dataset",
            fully_qualified_name="Foo.Dataset",
            column_details=[
                {
                    "name": "urn",
                    "type": "string",
                    "description": "The primary identifier for the dataset entity.",
                    "isPrimaryKey": True,
                    "foreignKeys": [],
                    "nullable": False,
                },
                {
                    "name": "upstreamLineage",
                    "type": "upstreamLineage",
                    "description": "Upstream lineage of a dataset",
                    "foreignKeys": [
                        {
                            "tableId": "urn:li:dataset:(urn:li:dataPlatform:datahub,Dataset,PROD)",
                            "fieldName": "urn",
                            "tableName": "Dataset",
                        }
                    ],
                    "isPrimaryKey": False,
                    "nullable": False,
                },
            ],
            retention_period_in_days=None,
            source_dataset_name="",
            where_to_access_dataset="",
            data_sensitivity_level=SecurityClassification.OFFICIAL,
            tags=["some-tag"],
            major_version=1,
            relationships={
                RelationshipType.PARENT: [
                    RelatedEntity(id="urn:li:container:databse", name="database")
                ]
            },
            domain="",
            last_updated=datetime(2024, 3, 5, 6, 16, 47, 814000, tzinfo=timezone.utc),
        )

    def test_get_dataset_minimal_properties(
        self,
        datahub_client,
        base_mock_graph,
    ):
        urn = "abc"
        datahub_response = {
            "dataset": {
                "platform": {"name": "datahub"},
                "name": "notinproperties",
                "properties": {},
                "container_relations": {
                    "total": 0,
                },
                "data_product_relations": {"total": 0, "relationships": []},
                "schemaMetadata": {"fields": []},
            }
        }
        base_mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

        dataset = datahub_client.get_table_details(urn)

        assert dataset == TableMetadata(
            name="notinproperties",
            fully_qualified_name="notinproperties",
            description="",
            column_details=[],
            retention_period_in_days=None,
            source_dataset_name="",
            where_to_access_dataset="",
            data_sensitivity_level=SecurityClassification.OFFICIAL,
            tags=[],
            major_version=1,
            relationships={},
            domain="",
            last_updated=None,
        )

    def test_get_chart_details(self, datahub_client, base_mock_graph):
        urn = "urn:li:chart:(justice-data,absconds)"
        datahub_response = {
            "chart": {
                "urn": "urn:li:chart:(justice-data,absconds)",
                "type": "CHART",
                "platform": {"name": "justice-data"},
                "relationships": {"total": 0, "relationships": []},
                "ownership": None,
                "properties": {
                    "name": "Absconds",
                    "externalUrl": "https://data.justice.gov.uk/prisons/public-protection/absconds",
                    "description": "a test description",
                    "customProperties": [],
                    "lastModified": {"time": 0},
                },
            },
            "extensions": {},
        }
        base_mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

        chart = datahub_client.get_chart_details(urn)
        assert chart == ChartMetadata(
            name="Absconds",
            description="a test description",
            external_url="https://data.justice.gov.uk/prisons/public-protection/absconds",
        )

    def test_create_athena_database_and_table(
        self,
        datahub_client,
        base_mock_graph,
        database,
        table,
        tmp_path,
        check_snapshot,
        golden_file_in_db,
    ):
        """
        Case where we create separate database and table
        """
        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in_db)
        with patch(
            "data_platform_catalogue.client.datahub.datahub_client.DataHubCatalogueClient.check_entity_exists_by_urn"
        ) as mock_exists:
            mock_exists.return_value = True
            fqn_db = datahub_client.upsert_athena_database(metadata=database)
            fqn_t = datahub_client.upsert_athena_table(metadata=table)

        fqn_db_out = "urn:li:container:my_database"
        assert fqn_db == fqn_db_out

        fqn_t_out = (
            "urn:li:dataset:(urn:li:dataPlatform:athena,my_database.my_table,PROD)"
        )
        assert fqn_t == fqn_t_out

        output_file = Path(tmp_path / "datahub_create_athena_table.json")
        base_mock_graph.sink_to_file(output_file)
        check_snapshot("datahub_create_athena_table.json", output_file)

    def test_create_athena_table_with_metadata(
        self,
        datahub_client,
        table,
        database,
        base_mock_graph,
        tmp_path,
        check_snapshot,
        golden_file_in_db,
    ):
        """
        Case where we create a dataset (athena table) and container (athena database)
        via upsert_athena_table method
        """
        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in_db)

        with patch(
            "data_platform_catalogue.client.datahub.datahub_client.DataHubCatalogueClient.check_entity_exists_by_urn"
        ) as mock_exists:
            mock_exists.return_value = True
            fqn = datahub_client.upsert_athena_table(
                metadata=table,
                database_metadata=database,
            )
        fqn_out = (
            "urn:li:dataset:(urn:li:dataPlatform:athena,my_database.my_table,PROD)"
        )

        assert fqn == fqn_out

        output_file = Path(tmp_path / "datahub_create_athena_table_with_metadata.json")
        base_mock_graph.sink_to_file(output_file)
        check_snapshot("datahub_create_athena_table_with_metadata.json", output_file)

    def test_domain_does_not_exist_error(self, datahub_client, database):
        with pytest.raises(InvalidDomain):
            datahub_client.upsert_athena_database(metadata=database)

    def test_database_not_exist_with_no_metadata_given_error(
        self, datahub_client, table
    ):
        with pytest.raises(MissingDatabaseMetadata):
            datahub_client.upsert_athena_table(metadata=table)

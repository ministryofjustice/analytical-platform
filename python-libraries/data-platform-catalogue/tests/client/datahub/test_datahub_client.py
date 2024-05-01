from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from data_platform_catalogue.client.datahub_client import (
    DataHubCatalogueClient,
    InvalidDomain,
)
from data_platform_catalogue.client.exceptions import ReferencedEntityMissing
from data_platform_catalogue.entities import (
    AccessInformation,
    Chart,
    Column,
    ColumnRef,
    CustomEntityProperties,
    Database,
    DataSummary,
    DomainRef,
    EntityRef,
    Governance,
    OwnerRef,
    RelationshipType,
    Table,
    TagRef,
    UsageRestrictions,
)


class TestCatalogueClientWithDatahub:
    """
    Test that the contract with DataHubGraph has not changed, using a mock.

    If this is the case, then the final metadata graph should match a snapshot we took earlier.
    """

    @pytest.fixture
    def database(self):
        return Database(
            name="my_database",
            description="little test db",
            governance=Governance(
                data_owner=OwnerRef(
                    urn="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
                    display_name="April Gonzalez",
                    email="abc@digital.justice.gov.uk",
                ),
                data_stewards=[
                    OwnerRef(
                        urn="abc",
                        display_name="Jonjo Shelvey",
                        email="j.shelvey@digital.justice.gov.uk",
                    )
                ],
            ),
            domain=DomainRef(urn="LAA", display_name="LAA"),
            last_modified=datetime(2020, 5, 17),
            creation_date=datetime(2020, 5, 17),
            access_information=AccessInformation(
                s3_location="s3://databucket/",
            ),
            tags=[TagRef(urn="test", display_name="test")],
            platform=EntityRef(urn="urn:li:dataPlatform:athena", display_name="athena"),
            custom_properties=CustomEntityProperties(
                usage_restrictions=UsageRestrictions(
                    dpia_required=False,
                    dpia_location=None,
                ),
                access_information=AccessInformation(
                    where_to_access_dataset="analytical_platform",
                    s3_location="s3://databucket/",
                ),
            ),
        )

    @pytest.fixture
    def table(self):
        return Table(
            urn=None,
            display_name="Foo.Dataset",
            name="Dataset",
            fully_qualified_name="Foo.Dataset",
            description="Dataset",
            relationships={
                RelationshipType.PARENT: [
                    EntityRef(
                        urn="urn:li:container:my_database", display_name="database"
                    )
                ]
            },
            domain=DomainRef(display_name="LAA", urn="LAA"),
            governance=Governance(
                data_owner=OwnerRef(
                    display_name="", email="Contact email for the user", urn=""
                ),
                data_stewards=[
                    OwnerRef(
                        display_name="", email="Contact email for the user", urn=""
                    )
                ],
            ),
            tags=[TagRef(display_name="some-tag", urn="urn:li:tag:Entity")],
            last_modified=datetime(2024, 3, 5, 6, 16, 47, 814000, tzinfo=timezone.utc),
            created=None,
            column_details=[
                Column(
                    name="urn",
                    display_name="urn",
                    type="string",
                    description="The primary identifier for the dataset entity.",
                    nullable=False,
                    is_primary_key=True,
                    foreign_keys=[
                        ColumnRef(
                            name="urn",
                            display_name="urn",
                            table=EntityRef(
                                urn="urn:li:dataset:(urn:li:dataPlatform:datahub,Dataset,PROD)",
                                display_name="Dataset",
                            ),
                        )
                    ],
                ),
            ],
            platform=EntityRef(urn="urn:li:dataPlatform:athena", display_name="athena"),
            custom_properties=CustomEntityProperties(
                access_information=AccessInformation(
                    where_to_access_dataset="", source_dataset_name="", s3_location=None
                ),
                data_summary=DataSummary(row_count=5),
                usage_restrictions=UsageRestrictions(
                    dpia_required=True,
                    dpia_location=None,
                ),
            ),
        )

    @pytest.fixture
    def table2(self):
        return Table(
            urn=None,
            display_name="Foo.Dataset",
            name="Dataset",
            fully_qualified_name="Foo.Dataset",
            description="Dataset",
            relationships={
                RelationshipType.PARENT: [
                    EntityRef(
                        urn="urn:li:container:my_database", display_name="database"
                    )
                ]
            },
            domain=DomainRef(display_name="LAA", urn="LAA"),
            governance=Governance(
                data_owner=OwnerRef(
                    display_name="", email="Contact email for the user", urn=""
                ),
                data_stewards=[
                    OwnerRef(
                        display_name="", email="Contact email for the user", urn=""
                    )
                ],
            ),
            tags=[TagRef(display_name="some-tag", urn="urn:li:tag:Entity")],
            last_modified=datetime(2024, 3, 5, 6, 16, 47, 814000, tzinfo=timezone.utc),
            created=None,
            column_details=[
                Column(
                    name="urn",
                    display_name="urn",
                    type="string",
                    description="The primary identifier for the dataset entity.",
                    nullable=False,
                    is_primary_key=True,
                    foreign_keys=[],
                ),
                Column(
                    name="upstreamLineage",
                    display_name="upstreamLineage",
                    type="upstreamLineage",
                    description="Upstream lineage of a dataset",
                    nullable=False,
                    is_primary_key=False,
                    foreign_keys=[
                        ColumnRef(
                            name="urn",
                            display_name="urn",
                            table=EntityRef(
                                urn="urn:li:dataset:(urn:li:dataPlatform:datahub,Dataset,PROD)",
                                display_name="Dataset",
                            ),
                        )
                    ],
                ),
            ],
            platform=EntityRef(urn="athena", display_name="athena"),
            custom_properties=CustomEntityProperties(
                access_information=AccessInformation(
                    where_to_access_dataset="", source_dataset_name="", s3_location=None
                ),
                data_summary=DataSummary(row_count=5),
                usage_restrictions=UsageRestrictions(
                    dpia_required=True,
                    dpia_location=None,
                ),
            ),
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
                                "urn": "urn:li:container:database",
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
                        {"key": "sensitivityLevel", "value": "OFFICIAL"}
                    ],
                    "lastModified": {"time": 1709619407814},
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
                            "sourceFields": [{"fieldPath": "urn"}],
                        },
                    ],
                },
            }
        }
        base_mock_graph.execute_graphql = MagicMock(return_value=datahub_response)
        with patch(
            "data_platform_catalogue.client.datahub_client.DataHubCatalogueClient.check_entity_exists_by_urn"
        ) as mock_exists:
            mock_exists.return_value = True
            dataset = datahub_client.get_table_details(urn)

        assert dataset == Table(
            urn=None,
            display_name="Dataset",
            name="Dataset",
            fully_qualified_name="Foo.Dataset",
            description="Dataset",
            relationships={
                RelationshipType.PARENT: [
                    EntityRef(urn="urn:li:container:database", display_name="database")
                ]
            },
            domain=DomainRef(display_name="", urn=""),
            governance=Governance(
                data_owner=OwnerRef(display_name="", email="", urn=""),
                data_stewards=[OwnerRef(display_name="", email="", urn="")],
            ),
            tags=[TagRef(display_name="some-tag", urn="urn:li:tag:Entity")],
            last_modified=datetime(2024, 3, 5, 6, 16, 47, 814000, tzinfo=timezone.utc),
            created=None,
            platform=EntityRef(urn="datahub", display_name="datahub"),
            custom_properties=CustomEntityProperties(
                usage_restrictions=UsageRestrictions(
                    status=None,
                    dpia_required=None,
                    dpia_location=None,
                ),
                access_information=AccessInformation(
                    where_to_access_dataset="", source_dataset_name="", s3_location=None
                ),
                data_summary=DataSummary(),
            ),
            column_details=[
                Column(
                    name="urn",
                    display_name="urn",
                    type="string",
                    description="The primary identifier for the dataset entity.",
                    nullable=False,
                    is_primary_key=True,
                    foreign_keys=[
                        ColumnRef(
                            name="urn",
                            display_name="urn",
                            table=EntityRef(
                                urn="urn:li:dataset:(urn:li:dataPlatform:datahub,Dataset,PROD)",
                                display_name="Dataset",
                            ),
                        )
                    ],
                )
            ],
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

        with patch(
            "data_platform_catalogue.client.datahub_client.DataHubCatalogueClient.check_entity_exists_by_urn"
        ) as mock_exists:
            mock_exists.return_value = True
            dataset = datahub_client.get_table_details(urn)

        assert dataset == Table(
            urn=None,
            display_name="notinproperties",
            name="notinproperties",
            fully_qualified_name="notinproperties",
            description="",
            relationships={},
            domain=DomainRef(display_name="", urn=""),
            governance=Governance(
                data_owner=OwnerRef(display_name="", email="", urn=""),
                data_stewards=[OwnerRef(display_name="", email="", urn="")],
            ),
            tags=[],
            last_modified=None,
            created=None,
            platform=EntityRef(urn="datahub", display_name="datahub"),
            custom_properties=CustomEntityProperties(
                usage_restrictions=UsageRestrictions(
                    status=None,
                    dpia_required=None,
                    dpia_location=None,
                ),
                access_information=AccessInformation(
                    where_to_access_dataset="", source_dataset_name="", s3_location=None
                ),
                data_summary=DataSummary(),
            ),
            column_details=[],
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

        with patch(
            "data_platform_catalogue.client.datahub_client.DataHubCatalogueClient.check_entity_exists_by_urn"
        ) as mock_exists:
            mock_exists.return_value = True
            chart = datahub_client.get_chart_details(urn)

        assert chart == Chart(
            urn="urn:li:chart:(justice-data,absconds)",
            display_name="Absconds",
            name="Absconds",
            fully_qualified_name="Absconds",
            description="a test description",
            relationships={},
            domain=DomainRef(display_name="", urn=""),
            governance=Governance(
                data_owner=OwnerRef(display_name="", email="", urn=""),
                data_stewards=[
                    OwnerRef(
                        display_name="", email="Contact email for the user", urn=""
                    )
                ],
            ),
            tags=[],
            last_modified=None,
            created=None,
            platform=EntityRef(urn="justice-data", display_name="justice-data"),
            custom_properties=CustomEntityProperties(
                usage_restrictions=UsageRestrictions(
                    status=None,
                    dpia_required=None,
                    dpia_location=None,
                ),
                access_information=AccessInformation(
                    where_to_access_dataset="", source_dataset_name="", s3_location=None
                ),
                data_summary=DataSummary(),
            ),
            external_url="https://data.justice.gov.uk/prisons/public-protection/absconds",
        )

    def test_upsert_table_and_database(
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
        base_mock_graph.import_file(golden_file_in_db)
        with patch(
            "data_platform_catalogue.client.datahub_client.DataHubCatalogueClient.check_entity_exists_by_urn"
        ) as mock_exists:
            mock_exists.return_value = True
            fqn_db = datahub_client.upsert_database(database=database)
            fqn_t = datahub_client.upsert_table(table=table)

        fqn_db_out = "urn:li:container:my_database"
        assert fqn_db == fqn_db_out

        fqn_t_out = "urn:li:dataset:(urn:li:dataPlatform:athena,database.Dataset,PROD)"
        assert fqn_t == fqn_t_out

        output_file = Path(tmp_path / "test_upsert_table_and_database.json")
        base_mock_graph.sink_to_file(output_file)
        check_snapshot("test_upsert_table_and_database.json", output_file)

    def test_upsert_table(
        self,
        datahub_client,
        table,
        base_mock_graph,
        tmp_path,
        check_snapshot,
        golden_file_in_db,
    ):
        """
        Case where we create a dataset via upsert_table method
        """
        mock_graph = base_mock_graph
        mock_graph.import_file(golden_file_in_db)

        with patch(
            "data_platform_catalogue.client.datahub_client.DataHubCatalogueClient.check_entity_exists_by_urn"
        ) as mock_exists:
            mock_exists.return_value = True
            fqn = datahub_client.upsert_table(
                table=table,
            )
        fqn_out = "urn:li:dataset:(urn:li:dataPlatform:athena,database.Dataset,PROD)"

        assert fqn == fqn_out

        output_file = Path(tmp_path / "test_upsert_table.json")
        base_mock_graph.sink_to_file(output_file)
        check_snapshot("test_upsert_table.json", output_file)

    def test_domain_does_not_exist_error(self, datahub_client, database):
        with pytest.raises(InvalidDomain):
            datahub_client.upsert_database(database=database)

    def test_database_not_exist_given_error(self, datahub_client, table, database):
        with pytest.raises(ReferencedEntityMissing):
            datahub_client.upsert_table(table=table)

    def test_get_custom_property_key_value_pairs(self, datahub_client, database):
        datahub_client._get_custom_property_key_value_pairs(database.custom_properties)

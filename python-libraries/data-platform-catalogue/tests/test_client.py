from pathlib import Path

import pytest
from data_platform_catalogue.client import (
    DataHubCatalogueClient,
    OpenMetadataCatalogueClient,
    ReferencedEntityMissing,
)
from data_platform_catalogue.entities import (
    CatalogueMetadata,
    DataProductMetadata,
    TableMetadata,
)
from datahub.api.entities.dataproduct.dataproduct import DataProduct
from freezegun import freeze_time
from tests.test_helpers.graph_helpers import MockDataHubGraph
from tests.test_helpers.mce_helpers import check_golden_file

FROZEN_TIME = "2023-04-14 07:00:00"


@freeze_time(FROZEN_TIME)
@pytest.mark.parametrize(
    "data_product_filename, upsert,golden_filename",
    [
        ("dataproduct.yaml", False, "golden_dataproduct_out.json"),
        ("dataproduct_upsert.yaml", True, "golden_dataproduct_out_upsert.json"),
    ],
    ids=["update", "upsert"],
)
def test_dataproduct_from_yaml(
    pytestconfig: pytest.Config,
    test_snapshots_dir: Path,
    tmp_path: Path,
    base_mock_graph: MockDataHubGraph,
    data_product_filename: str,
    upsert: bool,
    golden_filename: str,
) -> None:
    data_product_file = test_snapshots_dir / data_product_filename
    mock_graph = base_mock_graph
    data_product = DataProduct.from_yaml(data_product_file, mock_graph)
    assert data_product._resolved_domain_urn == "urn:li:domain:12345"
    assert data_product.assets is not None
    assert len(data_product.assets) == 3

    for mcp in data_product.generate_mcp(upsert=upsert):
        mock_graph.emit(mcp)

    output_file = Path(tmp_path / "test_dataproduct_out.json")
    mock_graph.sink_to_file(output_file)
    golden_file = Path(test_snapshots_dir / golden_filename)
    check_golden_file(pytestconfig, output_file, golden_file)


@freeze_time(FROZEN_TIME)
def test_dataproduct_from_datahub(
    pytestconfig: pytest.Config,
    test_snapshots_dir: Path,
    tmp_path: Path,
    base_mock_graph: MockDataHubGraph,
) -> None:
    mock_graph = base_mock_graph
    golden_file = Path(test_snapshots_dir / "golden_dataproduct_out.json")
    mock_graph.import_file(golden_file)

    data_product: DataProduct = DataProduct.from_datahub(
        mock_graph, id="urn:li:dataProduct:pet_of_the_week"
    )
    assert data_product.domain == "urn:li:domain:12345"
    assert data_product.assets is not None
    assert len(data_product.assets) == 3

    # validate that output looks exactly the same

    for mcp in data_product.generate_mcp(upsert=False):
        mock_graph.emit(mcp)

    output_file = Path(tmp_path / "test_dataproduct_to_datahub_out.json")
    mock_graph.sink_to_file(output_file)
    golden_file = Path(test_snapshots_dir / "golden_dataproduct_out.json")
    check_golden_file(pytestconfig, output_file, golden_file)


class TestCatalogueClient:
    def mock_service_response(self, fqn):
        return {
            "fullyQualifiedName": fqn,
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "serviceType": "Glue",
        }

    def mock_database_response(self, fqn):
        return {
            "fullyQualifiedName": fqn,
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "service": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "Glue",
            },
        }

    def mock_schema_response(self, fqn):
        return {
            "fullyQualifiedName": fqn,
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "service": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "Glue",
            },
            "database": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "",
            },
        }

    def mock_table_response_omd(self):
        return {
            "fullyQualifiedName": "my_table",
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "service": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "Glue",
            },
            "database": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "",
            },
            "databaseSchema": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "",
            },
            "columns": [],
        }

    def mock_user_response(self, fqn):
        return {
            "email": "justice@justice.gov.uk",
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
        }

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
    def omd_client(self, requests_mock) -> OpenMetadataCatalogueClient:
        requests_mock.get(
            "http://example.com/api/v1/system/version",
            json={"version": "1.2.0.1", "revision": "1", "timestamp": 0},
        )

        return OpenMetadataCatalogueClient(
            jwt_token="abc", api_url="http://example.com/api"
        )

    @pytest.fixture
    def datahub_client(self, base_mock_graph) -> DataHubCatalogueClient:
        return DataHubCatalogueClient(
            jwt_token="abc", api_url="http://example.com/api/gms", graph=base_mock_graph
        )

    def test_create_service_omd(self, omd_client, requests_mock):
        requests_mock.put(
            "http://example.com/api/v1/services/databaseServices",
            json=self.mock_service_response("some-service"),
        )

        fqn = omd_client.upsert_database_service()

        assert requests_mock.last_request.json() == {
            "name": "data-platform",
            "displayName": "Data platform",
            "serviceType": "Glue",
            "connection": {"config": {}},
        }
        assert fqn == "some-service"

    def test_create_database_omd(self, request, omd_client, requests_mock, catalogue):
        requests_mock.put(
            "http://example.com/api/v1/databases",
            json=self.mock_database_response("some-db"),
        )

        fqn: str = omd_client.upsert_database(
            metadata=catalogue, service_fqn="data-platform"
        )
        assert requests_mock.last_request.json() == {
            "name": "data_platform",
            "displayName": None,
            "domain": None,
            "lifeCycle": None,
            "description": "All data products hosted on the data platform",
            "tags": [],
            "owner": {
                "id": "2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
                "type": "user",
                "name": None,
                "fullyQualifiedName": None,
                "description": None,
                "displayName": None,
                "deleted": None,
                "href": None,
            },
            "service": "data-platform",
            "default": False,
            "retentionPeriod": None,
            "extension": None,
            "sourceUrl": None,
        }
        assert fqn == "some-db"

    def test_create_schema(self, request, omd_client, requests_mock, data_product):
        requests_mock.put(
            "http://example.com/api/v1/databaseSchemas",
            json=self.mock_schema_response("some-schema"),
        )

        fqn = omd_client.upsert_schema(
            metadata=data_product, database_fqn="data-product"
        )
        assert requests_mock.last_request.json() == {
            "name": "my_data_product",
            "displayName": None,
            "domain": None,
            "lifeCycle": None,
            "description": "bla bla",
            "owner": {
                "deleted": None,
                "description": None,
                "displayName": None,
                "fullyQualifiedName": None,
                "href": None,
                "id": "2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
                "name": None,
                "type": "user",
            },
            "database": "data-product",
            "tags": [
                {
                    "description": None,
                    "displayName": None,
                    "name": None,
                    "href": None,
                    "labelType": "Automated",
                    "source": "Classification",
                    "state": "Confirmed",
                    "style": None,
                    "tagFQN": "test",
                }
            ],
            "retentionPeriod": "P365D",
            "extension": None,
            "sourceUrl": None,
        }
        assert fqn == "some-schema"

    def test_create_table_omd(self, request, omd_client, requests_mock, table):
        requests_mock.put(
            "http://example.com/api/v1/tables",
            json=self.mock_table_response_omd(),
        )

        fqn = omd_client.upsert_table(
            metadata=table, schema_fqn="data-platform.data-product.schema"
        )
        assert requests_mock.called
        assert requests_mock.last_request.json() == {
            "name": "my_table",
            "displayName": None,
            "domain": None,
            "lifeCycle": None,
            "description": "bla bla",
            "dataProducts": None,
            "tableType": None,
            "columns": [
                {
                    "name": "foo",
                    "displayName": None,
                    "dataType": "STRING",
                    "arrayDataType": None,
                    "dataLength": None,
                    "precision": None,
                    "scale": None,
                    "dataTypeDisplay": None,
                    "description": "a",
                    "fullyQualifiedName": None,
                    "tags": None,
                    "constraint": None,
                    "ordinalPosition": None,
                    "jsonSchema": None,
                    "children": None,
                    "customMetrics": None,
                    "profile": None,
                },
                {
                    "name": "bar",
                    "displayName": None,
                    "dataType": "INT",
                    "arrayDataType": None,
                    "dataLength": None,
                    "precision": None,
                    "scale": None,
                    "dataTypeDisplay": None,
                    "description": "b",
                    "fullyQualifiedName": None,
                    "tags": None,
                    "constraint": None,
                    "ordinalPosition": None,
                    "jsonSchema": None,
                    "children": None,
                    "customMetrics": None,
                    "profile": None,
                },
            ],
            "tableConstraints": None,
            "tablePartition": None,
            "tableProfilerConfig": None,
            "owner": None,
            "databaseSchema": "data-platform.data-product.schema",
            "tags": [],
            "viewDefinition": None,
            "retentionPeriod": "P365D",
            "extension": None,
            "sourceUrl": None,
            "fileFormat": None,
        }
        assert fqn == "my_table"

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

    def test_404_handling_omd(self, request, omd_client, requests_mock, table):
        requests_mock.put(
            "http://example.com/api/v1/tables",
            status_code=404,
            json={"code": "something", "message": "something"},
        )

        with pytest.raises(ReferencedEntityMissing):
            omd_client.upsert_table(
                metadata=table, schema_fqn="data-platform.data-product.schema"
            )

    def test_get_user_id(self, request, requests_mock, omd_client):
        requests_mock.get(
            "http://example.com/api/v1/users/name/justice",
            json={
                "email": "justice@justice.gov.uk",
                "name": "justice",
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            },
        )

        user_id = omd_client.get_user_id("justice@justice.gov.uk")

        assert "39b855e3-84a5-491e-b9a5-c411e626e340" in str(user_id)

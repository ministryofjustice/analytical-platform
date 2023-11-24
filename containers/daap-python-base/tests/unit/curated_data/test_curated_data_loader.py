import json
import logging
from unittest.mock import patch

import pytest
from curated_data.curated_data_loader import CuratedDataCopier
from data_platform_paths import DataProductElement
from data_product_metadata import DataProductSchema

test_metadata = {
    "name": "test_product",
    "description": "just testing the metadata json validation/registration",
    "domain": "MoJ",
    "dataProductOwner": "matthew.laverty@justice.gov.uk",
    "dataProductOwnerDisplayName": "matt laverty",
    "email": "matthew.laverty@justice.gov.uk",
    "status": "draft",
    "retentionPeriod": 3000,
    "dpiaRequired": False,
    "schemas": ["test_table", "test_table1"],
}


changes1 = {
    "removed_columns": ["col_1"],
    "added_columns": None,
    "types_changed": None,
    "descriptions_changed": None,
}

changes2 = {
    "removed_columns": ["col_1"],
    "added_columns": None,
    "types_changed": ["col_1"],
    "descriptions_changed": None,
}

changes3 = {
    "removed_columns": ["col_1"],
    "added_columns": ["col_3", "col_4"],
    "types_changed": None,
    "descriptions_changed": ["col_2"],
}

valid_copy1 = True
valid_copy2 = False
valid_copy3 = True

expected_copy1 = ["test_table", "test_table1"]
expected_copy2 = ["test_table1"]
expected_copy3 = ["test_table", "test_table1"]

test_params1 = [
    (changes1, valid_copy1, expected_copy1),
    (changes2, valid_copy2, expected_copy2),
    (changes3, valid_copy3, expected_copy3),
]

test_params2 = [
    (changes1, expected_copy1),
    (changes2, expected_copy2),
    (changes3, expected_copy3),
]


class TestCuratedDataCopier:
    @pytest.fixture(autouse=True)
    def setup(self, metadata_bucket, s3_client):
        self.s3_client = s3_client
        self.bucket_name = metadata_bucket

        s3_client.put_object(
            Body=json.dumps(test_metadata),
            Bucket=self.bucket_name,
            Key=f"{test_metadata['name']}/v1.0/metadata.json",
        )

    @pytest.mark.parametrize("changes, valid_copy, expected_copy", test_params1)
    def test_init(self, athena_client, glue_client, changes, valid_copy, expected_copy):
        new_schema = DataProductSchema(
            data_product_name="test_product",
            table_name="test_table",
            logger=logging.getLogger(),
            input_data={
                "tableDescription": "test",
                "columns": [{"name": "col_5", "type": "int", "description": "test"}],
            },
        )
        element = DataProductElement.load(new_schema.table_name, "test_product")
        copier = CuratedDataCopier(
            column_changes=changes,
            new_schema=new_schema,
            element=element,
            athena_client=athena_client,
            glue_client=glue_client,
            logger=logging.getLogger(),
        )

        assert copier.copy_updated_table == valid_copy
        assert copier.tables_to_copy == expected_copy

    @pytest.mark.parametrize("changes, expected_copy", test_params2)
    def test_run(self, s3_client, athena_client, glue_client, changes, expected_copy):
        schema = DataProductSchema(
            data_product_name="test_product",
            table_name="test_table",
            logger=logging.getLogger(),
            input_data={
                "tableDescription": "test",
                "columns": [{"name": "col_1", "type": "string", "description": "test"}],
            },
        )
        schema2 = DataProductSchema(
            data_product_name="test_product",
            table_name="test_table1",
            logger=logging.getLogger(),
            input_data={
                "tableDescription": "test",
                "columns": [
                    {"name": "col_500", "type": "string", "description": "test"}
                ],
            },
        )
        schema.convert_schema_to_glue_table_input_csv()
        schema2.convert_schema_to_glue_table_input_csv()
        with patch("data_product_metadata.s3_client", s3_client):
            schema.write_json_to_s3("test_product/v1.0/test_table/schema.json")
            schema.write_json_to_s3("test_product/v1.0/test_table1/schema.json")
        new_schema = DataProductSchema(
            data_product_name="test_product",
            table_name="test_table",
            logger=logging.getLogger(),
            input_data={
                "tableDescription": "test",
                "columns": [{"name": "col_5", "type": "int", "description": "test"}],
            },
        )
        new_schema.convert_schema_to_glue_table_input_csv()
        element = DataProductElement.load(new_schema.table_name, "test_product")
        copier = CuratedDataCopier(
            column_changes=changes,
            new_schema=new_schema,
            element=element,
            athena_client=athena_client,
            glue_client=glue_client,
            logger=logging.getLogger(),
        )
        with patch(
            "curated_data.curated_data_loader.start_query_execution_and_wait"
        ) as mock_query:
            with patch(
                "curated_data.curated_data_loader.refresh_table_partitions"
            ) as mock_refresh:
                mock_query.return_value = "qidyes"
                mock_refresh.return_value = "qidyes"

                schema_list = copier.run()

        schema_names = [schema.table_name for schema in schema_list]
        assert schema_names == expected_copy

import pytest
from validation import DataInvalid, type_is_compatible, validate_data_against_schema


@pytest.mark.parametrize(
    "registered_type,inferred_type,expected",
    [
        ("tinyint", "tinyint", True),
        ("smallint", "smallint", True),
        ("integer", "integer", True),
        ("int", "int", True),
        ("bigint", "bigint", True),
        ("float", "float", True),
        ("double", "double", True),
        ("decimal", "decimal", True),
        ("string", "string", True),
        ("boolean", "boolean", True),
        ("char", "char", True),
        ("timestamp", "timestamp", True),
        ("date", "date", True),
        ("array", "array", True),
        ("struct", "struct", True),
        ("garbage", "int", False),
        ("int", "garbage", False),
        ("tinyint", "smallint", True),
        ("tinyint", "int", True),
        ("tinyint", "bigint", True),
        ("tinyint", "float", False),
        ("tinyint", "double", False),
        ("tinyint", "decimal", False),
        ("tinyint", "string", False),
        ("tinyint", "boolean", False),
        ("tinyint", "timestamp", False),
        ("tinyint", "date", False),
        ("smallint", "tinyint", True),
        ("smallint", "int", True),
        ("smallint", "bigint", True),
        ("smallint", "float", False),
        ("smallint", "double", False),
        ("smallint", "decimal", False),
        ("smallint", "string", False),
        ("smallint", "boolean", False),
        ("smallint", "timestamp", False),
        ("smallint", "date", False),
        ("int", "tinyint", True),
        ("int", "smallint", True),
        ("int", "bigint", True),
        ("int", "float", False),
        ("int", "double", False),
        ("int", "decimal", False),
        ("int", "string", False),
        ("int", "boolean", False),
        ("int", "timestamp", False),
        ("int", "date", False),
        ("bigint", "tinyint", True),
        ("bigint", "smallint", True),
        ("bigint", "int", True),
        ("bigint", "float", False),
        ("bigint", "double", False),
        ("bigint", "decimal", False),
        ("bigint", "string", False),
        ("bigint", "boolean", False),
        ("bigint", "timestamp", False),
        ("bigint", "date", False),
        ("float", "tinyint", True),
        ("float", "smallint", True),
        ("float", "int", True),
        ("float", "bigint", True),
        ("float", "double", True),
        ("float", "decimal", True),
        ("float", "string", False),
        ("float", "boolean", False),
        ("float", "timestamp", False),
        ("float", "date", False),
        ("double", "tinyint", True),
        ("double", "smallint", True),
        ("double", "int", True),
        ("double", "bigint", True),
        ("double", "double", True),
        ("double", "decimal", True),
        ("double", "string", False),
        ("double", "boolean", False),
        ("double", "timestamp", False),
        ("double", "date", False),
        ("decimal", "tinyint", True),
        ("decimal", "smallint", True),
        ("decimal", "int", True),
        ("decimal", "bigint", True),
        ("decimal", "float", True),
        ("decimal", "double", True),
        ("decimal", "string", False),
        ("decimal", "boolean", False),
        ("decimal", "timestamp", False),
        ("decimal", "date", False),
        ("string", "tinyint", True),
        ("string", "smallint", True),
        ("string", "int", True),
        ("string", "bigint", True),
        ("string", "float", True),
        ("string", "double", True),
        ("string", "decimal", True),
        ("string", "boolean", True),
        ("string", "timestamp", True),
        ("string", "date", True),
        ("boolean", "tinyint", False),
        ("boolean", "smallint", False),
        ("boolean", "int", False),
        ("boolean", "bigint", False),
        ("boolean", "float", False),
        ("boolean", "double", False),
        ("boolean", "decimal", False),
        ("boolean", "string", False),
        ("boolean", "timestamp", False),
        ("boolean", "date", False),
        ("timestamp", "tinyint", False),
        ("timestamp", "smallint", False),
        ("timestamp", "int", False),
        ("timestamp", "bigint", False),
        ("timestamp", "float", False),
        ("timestamp", "double", False),
        ("timestamp", "decimal", False),
        ("timestamp", "boolean", False),
        ("date", "tinyint", False),
        ("date", "smallint", False),
        ("date", "int", False),
        ("date", "bigint", False),
        ("date", "double", False),
        ("date", "float", False),
        ("date", "decimal", False),
        ("date", "boolean", False),
        ("date", "timestamp", False),
    ],
)
def test_type_is_compatible(registered_type, inferred_type, expected):
    assert (
        type_is_compatible(registered_type=registered_type, inferred_type=inferred_type)
        == expected
    )


class TestValidateAgainstSchema:
    @pytest.fixture
    def schema(self):
        return {"foo": "string", "bar": "int", "baz": "timestamp"}

    def test_valid_match(self, schema):
        validate_data_against_schema(
            registered_schema_columns=schema, inferred_columns=schema
        )

    def test_lenient_match(self, schema):
        validate_data_against_schema(
            registered_schema_columns=schema,
            inferred_columns={"foo": "int", "bar": "smallint", "baz": "date"},
        )

    def test_missing_columns(self, schema):
        with pytest.raises(DataInvalid):
            validate_data_against_schema(
                registered_schema_columns=schema,
                inferred_columns={"foo": "int", "bar": "smallint"},
            )

    def test_extra_columns(self, schema):
        with pytest.raises(DataInvalid):
            validate_data_against_schema(
                registered_schema_columns=schema,
                inferred_columns=dict(**schema, extra="integer"),
            )

class DataInvalid(Exception):
    pass


def type_is_compatible(registered_type: str, inferred_type: str) -> bool:
    """
    Validate a type inferred from the dataset is compatible with the schema.

    This implementation adds some leniency for types that are different, but probably compatible.
    For example: a `long` type is wider than an `integer` which is wider than `short` and `byte`.
    It is always valid for the dataset to contain a narrower type than what is registered in the schema,
    such as when the schema requires long but we detected integers.

    We also allow some cases where the dataset has a wider type than is registered in the schema,
    because this might be down to a data quality issue, which we don't want to address at this stage.
    (i.e. for the purposes of schema validation, we consider all integral types interchangable,
    and all floating-point types interchangable.)

    For a full list of supported types, see the AWS athena documentation:
    https://docs.aws.amazon.com/athena/latest/ug/data-types.html
    """
    if registered_type == inferred_type:
        return True

    match (registered_type, inferred_type):
        case ("string", _):
            return True
        case ("timestamp", "date"):
            return True
        case (
            "tinyint" | "smallint" | "int" | "integer" | "bigint",
            "tinyint" | "smallint" | "int" | "integer" | "bigint",
        ):
            return True
        case (
            "float" | "double" | "decimal",
            "float"
            | "double"
            | "decimal"
            | "tinyint"
            | "smallint"
            | "int"
            | "integer"
            | "bigint",
        ):
            return True
        case _:
            return False


def validate_data_against_schema(
    registered_schema_columns: dict[str, str], inferred_columns: dict[str, str]
):
    """
    Checks that a dataset has a valid set of column names and types.

    This validation is intended to reject data early in the case where the entire dataset looks to be mismatched
    to the schema. This indicates that something is wrong on the data prouducer's end, e.g. something went wrong
    extracting from the source system, or the schema has changed, and the data producer needs to register a new
    version. We do not care about row-level data quality checks at this stage.
    """
    registered_names = set(registered_schema_columns.keys())
    actual_names = set(inferred_columns.keys())
    missing_names = registered_names - actual_names
    extra_names = actual_names - registered_names
    if missing_names and extra_names:
        raise DataInvalid(
            f"Columns do not match schema (missing: {missing_names}, extra: {extra_names})"
        )
    if missing_names:
        raise DataInvalid(f"Columns do not match schema (missing: {missing_names})")
    if extra_names:
        raise DataInvalid(f"Columns do not match schema (extra: {extra_names})")

    type_errors = []
    for name in registered_names:
        registered_type = registered_schema_columns[name]
        inferred_type = inferred_columns[name]

        if not type_is_compatible(
            registered_type=registered_type, inferred_type=inferred_type
        ):
            type_errors.append(
                f"{name} expected {registered_type}, got {inferred_type}"
            )

    if type_errors:
        raise DataInvalid(f"Columns do not match schema ({', '.join(type_errors)})")

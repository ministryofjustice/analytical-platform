from typing import BinaryIO

import pyarrow.compute as pc
import pyarrow.csv as csv
from data_platform_logging import DataPlatformLogger
from pyarrow.lib import StringArray


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


def validate_csv_format(input_stream: BinaryIO, logger: DataPlatformLogger):
    """
    Ensure the CSV does not contain newlines. Such embedded newlines are
    not supported by OpenCSVSerde so we would be unable to load the data
    via athena.
    For performance reasons, this uses a streaming reader and only scans the
    first ~1.5MB of the dataset.
    """
    try:
        streaming_reader = csv.open_csv(
            input_stream,
            read_options=csv.ReadOptions(block_size=1_500_000),
            parse_options=csv.ParseOptions(newlines_in_values=False),
        )
        chunk = streaming_reader.read_next_batch()
        for i, column in enumerate(chunk):
            if type(column) is StringArray:
                problems = column.filter(pc.match_substring(column, "\n"))
                if problems:
                    error_message = f"Column {i} has embedded newlines"
                    logger.info(error_message)
                    raise DataInvalid(f"Column {i} has embedded newlines")

    except Exception as e:
        raise DataInvalid("Unable to read CSV for validation") from e

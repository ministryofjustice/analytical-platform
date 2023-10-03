<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.1.0] - 2023-10-2

### Changed

- Added version to RawDataExtraction so table name is parsed
  correctly
- Add a test case to check table is parsed correctly

## [3.0.0] - 2023-10-2

### Added

- landing_data_prefix method
- get_latest_version function

### Changed

- Changed directory pathing structure to include version number and use load_timestamp

## [2.2.0] - 2023-09-29

### Added

- infer_glue_schema module, moved from daap-athena-load lambda.

### Changed

- infer_glue_schema.GlueSchemaGenerator.infer_from_raw_csv
  null_values list in pyarrow's read_csv method change from an
  empty list to [""] which results in intended schema inference.

## [2.1.3] - 2023-09-27

Added functions to standardise API JSON response formatting.

## [2.0.3] - 2023-09-27

Changed the name of the temporary raw table to replace dashes with underscores.

## [2.0.2] - 2023-09-26

Changed the regular expression pattern to get more specific output

## [2.0.1] - 2023-09-22

Moved common functions from daap-resync-unprocessed-files
container to base container

### Added

`extract_table_name_from_curated_path`
`extract_database_name_from_curated_path`
`extract_timestamp_from_curated_path` functions

## [2.0.0] - 2023-09-15

Many changes to `data_platform_paths` to separate out the concept of
"data product element" from "data product", and to account for data being
stored in different S3 buckets.

### Added

- `DataProductElement` class added to represent the many elements belonging to
  a data product that produce the resulting tables
- `get_raw_data_bucket()`, `get_curated_data_bucket()`,
  `get_metadata_bucket` and `get_log_bucket` functions

### Changed

- Renamed `ExtractionConfig` to `RawDataExtraction`. This now has an `element` attribute
  instead of `data_product_config`.

### Removed

- `DataProductConfig` no longer takes a `table_name` argument. Instead, call
  `data_product_config.element(name)` or `DataProductElement.load` to get a
  `DataProductElement` instance.
- `raw_data_prefix`, `curated_data_prefix` and `curated_data_table` on
  `DataProductConfig` now exclude the table name part. Use `DataProductElement`
  to get the prefix including table name.
- `raw_data_table` is now a method of `DataProductElement`, and returns a unique
  name each call.
- `get_bucket_name()` function is replaced by `get_raw_data_bucket()`,
  `get_curated_data_bucket()`, `get_metadata_bucket` and `get_log_bucket`.
- `DataProductConfig` `bucket_name` attribute is replaced by `raw_data_bucket`
  and `curated_data_bucket`, and `metadata_bucket`.
- Removed
  `data_product_raw_data_file_path`, `data_product_curated_data_prefix`,
  `data_product_metadata_file_path` and `data_product_log_bucket_and_key`
  (use `DataProductConfig` and `DataProductElement` classes instead).

## [1.0.2] - 2023-09-15

### Changed

- `get_data_product_metadata_spec_path` to better handle sorting of semantic
  versioning.

## [1.0.1] - 2023-09-13

### Changed

- Added `__eq__` method to `DataProductConfig` for value-based equality checks

## [1.0.0] - 2023-09-12

### Added

- `data_platform_paths.DataProductConfig._log_file_path`
  (method moved from `data_platform_logging` module)

### Changed

- `data_platform_logging.DataPlatformLogger.write_log_dict_to_s3_json` to
  `_write_log_dict_to_s3_json`, with the method now writing to an s3 json file
  on every log call
- `data_platform_logging.DataPlatformLogger` gets log file path from
  `data_platform_paths`
- `data_platform_logging` now includes `security_opts` dict, the extra arguments
  to satisfy bucket security config in the data platform

## [0.6.0] - 2023-09-08

### Added

- `data_platform_paths.DataProductConfig.metadata_spec_path`
  (method moved from `data_product_metadata` module)

### Removed

- `data_product_metadata.get_bucket_name`
  (use `data_platform_paths.get_bucket_name` instead)
- `data_product_metadata.get_data_product_metadata_path`
  (use `data_platform_paths.get_data_product_metadata_path` instead)

## [0.5.0] - 2023-09-07

### Added

- data_platform_paths module. This contains code for generating paths to files
  in S3 and names of tables in Athena.

## [0.4.0] - 2023-09-01

### Added

- data_product_metadata python module. This contains code that will be used,
  intially by an API endpoint to create data product metadata, but in future,
  expanded to be usedin other endpoints too, such as an update_metadata endpoint.

## [0.3.0] - 2023-08-11

### Changed

- Fix GitHub Container Registry login

## [0.2.0] - 2023-08-11

### Changed

- Push image to GitHub Container Registry, so downstream builds can pull it

## [0.1.0]

###

- Initial image contains custom logging module in addition to python 3.11

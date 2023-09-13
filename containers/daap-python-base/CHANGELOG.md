<!-- markdownlint-disable MD003 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

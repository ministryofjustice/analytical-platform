<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.3.0] - 2023-11-21

### Added

- `count_files` helper function in tests

### Removed

- DataProductSchema.exists check
- 'ValueError' exception handling as glue delete table
  will no longer throw an exception back to the caller
- `test_table_schema_fail` as schema check no longer exists

### Changed

- tests for deletion of raw and curated files combined

## [2.2.1] - 2023-11-16

### Changed

- renamed VersionCreator to VersionManager to match versioning module

## [2.2.0] - 2023-11-15

### Changed

- update base image to 7.0.0

## [2.1.0] - 2023-11-13

### Changed

- update base image to 6.2.0
- update Dockerfile COPY command fixing `LAMBDA_TASK_ROOT` typo

## [2.0.1] - 2023-11-13

### Added

- structlog==23.2.0 to requirments.txt

## [2.0.0] - 2023-11-6

### Removed

- Most of the work done previously has now been moved to
  the `VersionCreator.update_metadata_remove_schemas` method
- `get_all_versions` moved to base
- `generate_all_element_version_prefixes` moved to base
- `delete_all_element_version_data_files` moved to base
- `s3_recursive_delete` moved to base
- `glue_utils.delete_glue_table` moved to base

## [1.0.1] 2023-11-6

### Changed

- Updated repository name in config.json

## [1.0.0]

### Added

- Initial container definition

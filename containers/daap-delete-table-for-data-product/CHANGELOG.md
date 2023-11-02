<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2023-11-2

### Removed

- Most of the work done previously has now been moved to
    the `VersionCreator.update_metadata_remove_schemas` method
- `get_all_versions` moved to base
- `generate_all_element_version_prefixes` moved to base
- `delete_all_element_version_data_files` moved to base
- `s3_recursive_delete` moved to base
- `glue_utils.delete_glue_table` moved to base

## [1.0.0]

### Added

- Initial container definition

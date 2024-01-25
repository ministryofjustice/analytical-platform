<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] 2024-01-24

### Added

- BaseCatalogueClient.list_data_products()

## [0.5.0] 2024-01-24

### Added

- Search function

## [0.4.0] 2024-01-19

### Breaking changes

- Changed `database_fqn`, `schema_fqn`, etc to a more generic
  `location: DataLocation` argument on all methods. This captures information
  about where a node in the metadata graph should be located, and what kind
  of database it comes from.

- Renamed `create_or_update_*` methods to `upsert_*`.

- Extracted `BaseCatalogueClient` base class from `CatalogueClient`. Use this
  as a type annotation to avoid coupling to the OpenMetadata implementation.

- Renamed the existing `CatalogueClient` implementation to
  `OpenMetadataCatalogueClient`.

### Added

- Added `DataHubCatalogueClient` to support DataHub's GMS as the catalogue
  implementation.

## [0.3.1] 2023-11-13

- Updated to OpenMetadata 1.2

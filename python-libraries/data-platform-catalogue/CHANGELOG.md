<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.21.0] 2023-03-19

### Added

- A ChartMetadata class with very limited attributes
- ResultType.CHART
- A GraphQL query for chart details
- SearchClient._parse_chart, incorporated chart parsing into the normal search method
- DataHubCatalogueClient.get_chart_details for the chart display page

### Changed

- Altered GraphQL search query to include chart parsing

## [0.20.0] 2024-03-15

### Added

- `upsert_athena_database` and `upsert_athena_table` methods to
  `DataHubCatalogueClient` - to register/update databases or tables in
  datahub. These methods do not create a domain if it does not exist.
- `DatabaseMetadata` class to `entities.py` - for defining metadata for an
  athena database
- `DatabaseStatus` enum to `entities.py`
- 2 custom exceptions in `datahub_client.py` for invalid domains and missing metadata.

### Changed

- `entities.TableMetadata` to have some optional properties to the class -
  `parent_database_name`, `domain`, `row_count`
- `entities.SecurityClassification` to remove classicifation we will not be using.

## [0.19.2] 2024-03-07

### Added

- `_get_matched_fields` static method to return matched fields including logic
  for the values of custom property fields.

### Changed

- changed query test matches to include a customProperties field with value

## [0.19.1] 2024-03-07

### Changed

- Fix error executing getDataset query and added end-to-end test

## [0.19.0] 2024-03-06

### Added

- `get_table_details(urn)` method to fetch table details including column level metadata

## [0.18.1] 2024-03-05

### Changed

- `SearchResult.fully_qualified_name` now returns `name` if datahub metadata
  property `qualifiedName` has a value of `None`, which it can do in the
  case of dbt ingestions.

## [0.18.0] 2024-03-04

### Added

- `SearchResult` now returns a fully qualified name along with name
  for datasets and data products. This is implemented in the clients
  `search` method. We default fully_qualified_name for a data product
  entity to `name`

## [0.17.0] 2024-02-28

### Added

- upsert_table now sets datset name as single table name and
  `qualifiedName` as the fully qualified name we define.

## [0.16.1] 2024-02-20

### Added

- a get_glossary_terms to catalogue ABC for mocking in pytest

## [0.16.0] 2024-02-20

### Added

- a get_glossary method in the datahub client and SearchClient

## [0.15.0] 2024-02-20

### Added

- a list_data_product_assets method the the datahub client and SearchClient

## [0.14.0] 2024-02-19

### Changed

- bugfix - search now returns correct page results, where start is
  individual search result index.
- bugfix - `upsert_table` client method now adds dataset name to datahub.
- bugfix - `upsert_table` client method no longer duplicates assets assocaited
  with data product.

## [0.13.0] 2024-02-14

### Changed

- Added subdomain property to dataproduct
- Renamed `source_dataset_location` to `where_to_access_dataset`

### Removed

- openmetadata code

## [0.12.0] 2024-02-08

### Changed

- Added fix so upsert_table does not overwrite data product metadata.

## [0.11.0] 2024-02-05

### Changed

- Added data product level and table level metadata items
- Added metadata items to the datahub client

## [0.10.0] 2024-02-01

### Changed

- Custom properties are now added to the metadata of each search result
- Datasets return domain information
- Domain information is now returned as `domain_id` and `domain_name` metadata

## [0.9.0] 2024-01-31

### Added

Added the ability to sort search results

- Added class `SortOption` to allow sorting of search results
- Added parameter `sort` to `SearchClient.search()`

## [0.8.0] 2024-01-29

### Added

Enhanced the metadata returned with search results:

- Added `number_of_assets` to data product metadata
- Added `data_products` and `total_data_products` to dataset metadata
- Added separate search_facets method
- Added `SearchFacets`` class to make it easier to present facets

### Changed

- Replaced deprecated Datahub `filters` parameter with `orFilters`

## [0.7.0] 2024-01-25

### Added

- Added filters param to the search function
- Return facets attribute to the search response. This is a dictionary mapping
  fieldnames to `FacetOptions`, which expose values, display names and the
  count of results with that value.

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

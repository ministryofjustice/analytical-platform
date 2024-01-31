# Data platform catalogue

This library is part of the Ministry of Justice data platform.

It publishes object metadata to a data catalogue, so that the
metadata can be made discoverable by consumers.

Broadly speaking, a catalogue stores a _metadata graph_, consisting of
_data assets_. Data assets could be **tables**, **schemas** or **databases**.

## How to install

To install the package using `pip`, run:

```shell
pip install ministryofjustice-data-platform-catalogue
```

## Terminology

- **Data assets** - Any databases, tables, or schemas within the metadata graph
- **Data products** - Groupings of data assets that are published for
  reuse across MOJ. In the data platform, the concepts of database and data
  product are similar, but they may be represented as different entities in the
  catalogue.
- **Domains** - allow metadata to be grouped into different service areas that have
  their own governance, like HMCTS, HMPPS, OPG, etc.

## Example usage

```python
from data_platform_catalogue import (
  DataHubCatalogueClient,
  BaseCatalogueClient, DataLocation, CatalogueMetadata,
  DataProductMetadata, TableMetadata,
  CatalogueError
)

client: BaseCatalogueClient = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

data_product = DataProductMetadata(
    name = "my_data_product",
    description = "bla bla",
    version = "v1.0.0",
    owner = "7804c127-d677-4900-82f9-83517e51bb94",
    email = "justice@justice.gov.uk",
    retention_period_in_days = 365,
    domain = "HMCTS",
    dpia_required = False
)

table = TableMetadata(
  name = "my_table",
  description = "bla bla",
  column_details=[
      {"name": "foo", "type": "string", "description": "a"},
      {"name": "bar", "type": "int", "description": "b"},
  ],
  retention_period_in_days = 365,
  major_version = 1
)

try:
    table_fqn = client.upsert_table(
        metadata=table,
        data_product_metadata=data_product,
        location=DataLocation("test_data_product_v1"),
    )
except CatalogueError:
  print("oh no")
```

## Search example

```python
response = client.search()

# Total results across all pages
print(response.total_results)

# Iterate over search results
for item in response.page_results:
  print(item)

# Iterate over facet options
for option in response.facets.options('domains'):
  print(option.label)
  print(option.value)
  print(option.count)

# Include a filter
client.search(filters=[MultiSelectFilter("domains", [response.facets['domains'][0].value])])
```

## Search filters

### Datahub

Basic filters:

- urn
- customProperties
- browsePaths / browsePathsV2
- deprecated (boolean)
- removed (boolean)
- typeNames
- name, qualifiedName
- description, hasDescription

Timestamps:

- lastOperationTime (datetime)
- createdAt (timestamp)
- lastModifiedAt (timestamp)

URNs:

- platform / platformInstance
- tags, hasTags
- glossaryTerms, hasGlossaryTerms
- domains, hasDomain
- siblings
- owners, hasOwners
- roles, hasRoles
- container

## Catalogue Implementations

### DataHub

- Each data product within the MOJ data platform is created as a data product entity
- Each table is created as a dataset in DataHub
- Tables that reside in the same athena database (data_product_v1) should
  be placed within the same DataHub container.

## OpenMetadata

- Each MOJ data product is mapped to a database in the OpenMetadata catalogue
- We populate the schema level in openmetdata with a generic entry of `Tables`
- Each table is mapped to a table in openmetadata

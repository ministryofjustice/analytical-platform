# Data platform catalogue

This library is part of the Ministry of Justice data platform.

It provides functionality to publish object metadata to the OpenMetadata data catalogue
so that data products are discoverable.

## How to install

To install the package using `pip`, run:

```shell
pip install data-platform-catalogue
```

## Topology

- Each internal data platform catalogue is mapped to a database in the
  OpenMetadata catalogue
- Each data product is mapped to a schema
- Each table is mapped to a table

![Topology diagram](./diagram.png)

## Example usage

```python
from data_platform_catalogue import CatalogueClient

client = CatalogueClient(
    jwt_token="***",
    api_uri="https://catalogue.apps-tools.development.data-platform.service.justice.gov.uk/api"
)

assert client.is_healthy()

service_fqn = client.create_or_update_database_service(name="data_platform")
database_fqn = client.create_or_update_database(name="all_data_products", service_fqn=service_fqn)
schema_fqn = client.create_or_update_database(name="my_data_product", database_fqn=database_fqn)

table_fqn = client.create_or_update_table(
    name="my_table",
    schema_fqn=schema_fqn,
    column_types={"foo": "string", "bar": "int"}
)
```

# ADR-002 Use a dedicated repository for data product defintions

## Status

✅ Accepted

## Context

The [Cloud Platform](https://github.com/ministryofjustice/cloud-platform) and the [Modernisation Platform](https://user-guide.modernisation-platform.service.justice.gov.uk/) both employ separate GitHub repositories for defining services hosted on the platform, distinct from code which defines the platform itself.

In the context of the Data Platform, the current hypothesis is that the services created by users of the platform will be "data products" as defined in data mesh literature and our own [documentation](https://dsdmoj.atlassian.net/wiki/spaces/DataPlatform/pages/4270195993/What+is+a+Data+Product).

This allows for:

- Separation of repository access controls between platform maintainers and platform users, if required
- Clean separation of infrastructure code
- Separation of code validation (for example schema validation)
- Clear separation of pull requests between platform maintenance and platform usage

## Decision

Consistent with other MOJ platforms, use a dedicated [GitHub repository](https://github.com/ministryofjustice/data-platform-products) to define and manage data products.

## Consequences

- All architecture decision records (ADRs) should continue to be recorded in this, the main platform repository (including ADRs related to data products).
- We will have to manage an additional repository

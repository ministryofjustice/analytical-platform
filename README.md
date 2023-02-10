# Data Platform

[![repo standards badge](https://img.shields.io/badge/dynamic/json?color=blue&style=for-the-badge&logo=github&label=MoJ%20Compliant&query=%24.result&url=https%3A%2F%2Foperations-engineering-reports.cloud-platform.service.justice.gov.uk%2Fapi%2Fv1%2Fcompliant_public_repositories%2Fdata-platform)](https://operations-engineering-reports.cloud-platform.service.justice.gov.uk/public-github-repositories.html#data-platform "Link to report") [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/ministryofjustice/data-platform/badge)](https://api.securityscorecards.dev/projects/github.com/ministryofjustice/data-platform)


The Data Platform will be a centralised, in-house platform to provide hosting and tools for data

* storage
* discovery
* analysis
* dissemination
* governance

## About this repository

This is the Ministry of Justice mono-repo for work on the Data Platform.

Please read the [contributing guide](CONTRIBUTING.md) before sending pull requests,
or creating issues.

### Contents

This repository currently holds the Data Platform's:

- [Architecture Decision Records (ADR)](architecture/decision/README.md)

## Data Platform repositories

We have a series of repositories for our work. We have adopted the naming convention of naming each repository starting with `data-platform-*`. 
We also [name things](https://technical-guidance.service.justice.gov.uk/documentation/standards/naming-things.html#naming-things) so that users 
can understand what a repository does through its name.

| Name                                                                                           | Description                                                                               |
| ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [Data Platform (this repository)](https://github.com/ministryofjustice/data-platform)          | Core infrastructure, public facing documentation, feature work, enhancements, and issues  |
| [Data Platform products](https://github.com/ministryofjustice/data-platform-products)          | User-created services that are hosted on the Data Platform                                |
| [Modernisation Platform environments repo](https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/data-platform) | Hosting environment for the data platform |
<!--| [Data Platform user guide](https://github.com/ministryofjustice/data-platform)             | User-focussed documentation for how to get started and use the Cloud Platform             | -->

## Getting in touch

We are currently in the research and design phase, and are not yet accepting requests to host new data products.

In the meantime please get in touch via our `#data-platform` Slack channel with any questions.

<!--
## Service runbook information

Please note we do not provide support for data quality issues, or for apps dependent on the data platform. Please contact the relevant 
data or app owners via [*the directory of Data Platform services*]

### Incident response hours

Office hours, usually 8am-5pm on working days

-->

### Incident contact details

Slack: `#data-platform`
Email: `data-platform@digital.justice.gov.uk`

### Service team contact

As above - preferably our Slack channel: `#data-platform` (or email `data-platform@digital.justice.gov.uk`)

### Hosting environment

[Modernisation Platform](https://user-guide.modernisation-platform.service.justice.gov.uk/)

<!-- ### Consumers of this service:

(placeholder)

### **Services consumed by this:**

(placeholder) -->

### Last review date

7th February 2023

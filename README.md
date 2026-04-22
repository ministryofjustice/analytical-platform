# Ministry of Justice Analytical Platform

[![Ministry of Justice Repository Compliance Badge](https://github-community.service.justice.gov.uk/repository-standards/api/analytical-platform/badge?style=flat)](https://github-community.service.justice.gov.uk/repository-standards/analytical-platform)
[![🚀 Publish Documentation](https://github.com/ministryofjustice/analytical-platform/actions/workflows/publish-documentation.yml/badge.svg)](https://github.com/ministryofjustice/analytical-platform/actions/workflows/publish-documentation.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/ministryofjustice/analytical-platform/badge)](https://api.securityscorecards.dev/projects/github.com/ministryofjustice/analytical-platform)

## About this repository

The Analytical Platform provides users with a place to store, ingest and consume data.

This repository holds the Ministry of Justice’s Analytical Platforms published technical documentation and code to build the analytical infrastructure for our users.

For more information on the Analytical Platform please see the [user guidance](https://user-guidance.analytical-platform.service.justice.gov.uk/index.html).

## Analytical Platform repositories

We have a series of repositories for our work. We have adopted the naming
convention of naming each repository starting with `analytical-platform-*`.

We also [name things](https://technical-guidance.service.justice.gov.uk/documentation/standards/naming-things.html#naming-things)
so that users can understand what a repository does through its name.

The repositories we manage with terraform see [here](https://github.com/ministryofjustice/data-platform-github-access/blob/main/analytical-platform-repositories.tf).

| Name | Description |
| -------------- | -------------- |
| [Analytical Platform (this repository)](https://github.com/ministryofjustice/analytical-platform)          | Analytical Platform infrastructure, public facing documentation, feature work, enhancements, and issues  |
| [Analytical Platform Actions Runner](https://github.com/ministryofjustice/analytical-platform-actions-runner)          | contains the GitHub Actions Runner image used by the Analytical Platform  |
| [Analytical Platform App Cloud Platform Deployment](https://github.com/ministryofjustice/data-platform-app-template) | Template for Cloud Platform deployments of Analytical Platform Apps |
| [Analytical Platform Auth Proxy](https://github.com/ministryofjustice/analytics-platform-auth-proxy)          | This repository contains the authentication proxy image used by the Analytical Platform  |
| [Analytical Platform Control Panel](https://github.com/ministryofjustice/analytics-platform-control-panel)          | The Control Panel is a management tool which provides Data Analysts and Data Scientists data management and tooling  |
| [Analytical Platform Dashboard](https://github.com/ministryofjustice/analytical-platform-dashboard)          | The AP Dashboard is still in `development`   |
| [Analytical Platform GitHub Access](https://github.com/ministryofjustice/data-platform-github-access)          | This repository controls access to the Data Platform Service Area's GitHub which includes, Analytical Platform, Data Catalogue and Data Engineering's access to the Analytical Platform  |
| [Analytical Platform image build template](https://github.com/ministryofjustice/analytical-platform-image-build-template)          | contains the GitHub Actions Runner image used by the Analytical Platform  |
| [Analytical Platform Ingestion Notify](https://github.com/ministryofjustice/analytical-platform-ingestion-notify)          | Image for the Analytical Platform Ingestion service. It is deployed as an AWS Lambda function within the analytical-platform-ingestion account  |
| [Analytical Platform Ingestion Scan](https://github.com/ministryofjustice/analytical-platform-ingestion-scan)          | This repository contains the image used in the Analytical Platform Ingestion service. It is deployed as an AWS Lambda function within the analytical-platform-ingestion account and is called as part of the AWS Transfer Family Server workflows  |
| [Analytical Platform Ingestion Transfer](https://github.com/ministryofjustice/analytical-platform-ingestion-transfer)          | This repository contains the image  used in the Analytical Platform Ingestion service. It is deployed as an AWS Lambda function within the analytical-platform-ingestion account  |
| [Analytical Platform JML report](https://github.com/ministryofjustice/analytical-platform-jml-report)          | Creates a joiners movers leavers report  |
| [Analytical Platform Jupyter Notebook image](https://github.com/ministryofjustice/analytics-platform-jupyter-notebook)          | This repository contains the Jupyter Notebook image image used by the Analytical Platform  |
| [Analytical Platform Kubectl image](https://github.com/ministryofjustice/analytical-platform-kubectl)          | This repository contains the GitHub Kubectl image used by the Analytical Platform  |
| [Analytical Platform RShiny base image](https://github.com/ministryofjustice/analytical-platform-rshiny-open-source-base)          | This repository contains the GitHub RShiny Open Source Base image used by the Analytical Platform  |
| [Analytical Platform RStudio image](https://github.com/ministryofjustice/analytics-platform-rstudio)          | This repository contains the RStudio image used by the Analytical Platform  |
| [Analytical Platform support](https://github.com/ministryofjustice/data-platform-support)            | This repository is used for support and provides templated forms for our users          |
| [Analytical Platform User Guidancel](https://github.com/moj-analytical-services/user-guidance)          | User guidance for the Analytical Platform which is hosted on GitHub Pages [here](https://user-guidance.analytical-platform.service.justice.gov.uk/)  |
| [Analytical Platform Visual Studio Code](https://github.com/ministryofjustice/analytical-platform-visual-studio-code)          | This repository contains the Visual Studio Code image used by the Analytical Platform  |
| [Data Platform Services GitHub Access](https://github.com/ministryofjustice/data-platform-github-access/) | This repository manages access to Data Platform Service Area's GitHub including Analytical Platform, Data Catalogue and Data Engineering's access to Analytical Platform  |
| [Modernisation Platform environments repository](https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/data-platform) | Hosting environment for the Analytical Platform |

### Useful links

It may be also useful to look at:

- [Technical documentation](https://docs.analytical-platform.service.justice.gov.uk/)
- [Architecture Decision Records (ADRs)](https://docs.analytical-platform.service.justice.gov.uk/documentation/adrs/adr-index.html)

## Getting in touch

We are currently in the research and design phase, and are not yet accepting
requests to host new data products.

In the meantime please get in touch via our `#analytical-platform` Slack channel
with any questions.

<!--
## Service runbook information

Please note we do not provide support for data quality issues, or for apps
dependent on the Analytical Platform Please contact the relevant
data or app owners via [*the directory of Analytical Platform services*]

### Incident response hours

Office hours, usually 8am-5pm on working days

-->

### Incident contact details

Slack: [#ask-analytical-platform](https://moj.enterprise.slack.com/archives/C06TFT94JTC)
Email: `analytical-platform@digital.justice.gov.uk`

### Service team contact

As above - preferably our Slack channel: [#ask-analytical-platform](https://moj.enterprise.slack.com/archives/C06TFT94JTC) (or email `analytical-platform@digital.justice.gov.uk`)

## Hosting environment

[Modernisation Platform](https://user-guide.modernisation-platform.service.justice.gov.uk/)

<!-- ### Consumers of this service:

(placeholder)

### **Services consumed by this:**

(placeholder) -->

## Editing and publishing the Technical Documentation

The [published](https://docs.analytical-platform.service.justice.gov.uk/)
documentation is created by editing `*.html.md.erb` files,
found in the [`source`](/source/) folder.

The syntax is Markdown, more details can be found [here](https://daringfireball.net/projects/markdown/).

While editing the files locally, you can start a Docker container that will use
Middleman to act as a server hosting the web pages. See [preview docs](#preview-docs).

Every change should be reviewed in a pull request, no matter how minor.
PR request reviewer/s should be enabled within the main branch protection
settings.

Merging the changes to the `main` branch automatically publishes the
changes via GH Action. See [publishing](#publishing).

### Preview docs

You can preview how your changes will look, if you've cloned this repository
to your local machine, run this command:

```bash
make preview
```

This will run a preview web server on <http://localhost:4567> which you can
open in your browser.

Use `bash scripts/docs/docker.sh check` to compile
the site to HTML and check the URLs are valid.

This is only accessible on your computer, and won't be accessible to anyone
else.

For more details see the
[tech-docs-github-pages-publisher](https://github.com/ministryofjustice/tech-docs-github-pages-publisher)
repository.

### Publishing

Any changes you push/merge into the
`main` branch should be published to GitHub Pages site automatically.

### Template configuration

The web page layout is configured using the config/tech-docs.yml file.

The template can be configured in [config/tech-docs.yml](config/tech-docs.yml)

Further configuration options are described on the Tech Docs Template
site: [Global Configuration](https://github.com/alphagov/tdt-documentation/blob/main/config/tech-docs.yml).

## Contributing

Please read the [contributing guide](CONTRIBUTING.md) before sending pull
requests, or creating issues.

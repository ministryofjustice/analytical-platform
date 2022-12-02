# ADR-001 Use the Modernisation Platform

## Status

🤔 Proposed

## Context

Historically the projects and products in the data space,
leading up to the data platform,
have been managed in the team's own AWS accounts.
This has caused issues from misalignment with security baselines,
and meant that some of their AWS accounts were managed independently of our internal best practice.

The available options are:

* The [Cloud Platform](https://user-guide.cloud-platform.service.justice.gov.uk/)
* The [Modernisation Platform](https://user-guide.modernisation-platform.service.justice.gov.uk/)
* Self-management

## Decision

We will use the Modernisation Platform for hosting.

We have had 5 years experience of self-managing a collection of AWS accounts on the Analytical Platform,
and it has not been a positive experience.

While the Cloud Platform is a great environment for us to encourage our customers to host their services,
the data platform itself falls outside the type of system that the [Cloud Platform is best at hosting](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/concepts/what-is-the-cloud-platform.html).

## Consequences

As a result of this decision we will benefit from all of the features documented in the [Modernisation User Guide](https://user-guide.modernisation-platform.service.justice.gov.uk/user-guide/our-offer-to-you.html).

In addition to the security baseline,
and the automatic environment provisioning,
we will likely make use of many other features that we would otherwise have to build ourselves when we could be enhancing the data platform itself.

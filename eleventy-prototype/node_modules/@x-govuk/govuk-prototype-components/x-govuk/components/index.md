---
templateEngineOverride: njk
homepage: true
layout: product
includeInBreadcrumbs: true
collection: Components
override:tags: []
pagination:
  data: collections.component
  size: 20
eleventyComputed:
  title: GOV.UK Prototype Components
  description: Common and experimental components that are not yet part of the GOV.UK Design System
  permalink: "/"
---
{% filter markdown %}{% include "../../README.md" %}{% endfilter %}

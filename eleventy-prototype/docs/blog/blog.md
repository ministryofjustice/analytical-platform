---
eleventyNavigation:
  key: Blog
  order: 2
layout: collection
title: Blog
includeInBreadcrumbs: true
description: Latest news on the Data Platform's development
tags: []
paginationHeading: false
pagination:
  data: collections.getAllBlogsOrderedByTitle
  size: 5
aside:
  title: Aside
  content: | 
    A small portion of content that is **indirectly** related to the main content.
related:
  sections:
    - title: Related links
      items:
        - text: Layouts
          href: ../../layouts
        - text: Options
          href: ../../options
      subsections:
        - title: Eleventy documentation
          items:
          - text: Front matter data
            href: https://www.11ty.dev/docs/data-frontmatter/
---
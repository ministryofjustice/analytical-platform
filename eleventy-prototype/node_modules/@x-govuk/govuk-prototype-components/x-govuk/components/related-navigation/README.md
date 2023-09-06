# Related navigation

The related navigation component is [a GOV.UK Publishing specific component](https://components.publishing.service.gov.uk/component-guide/related_navigation).

This component may be useful if you are prototyping guidance pages that could be published on GOV.UK, or if your service needs to show related navigation.

## Example usage

```njk
{{ xGovukRelatedNavigation({
  sections: [{
    items: [{
      text: "Find and compare schools in England",
      href: "/school-performance-tables"
    }, {
      text: "Types of school",
      href: "/types-of-school"
    }],
    subsections: [{
      title: "Explore the topic",
      items: [{
        text: "Schools and curriculum",
        href: "/browse/education/school-life"
      }]
    }]
  }]
}) }}
```

## Component options

Use options to customise the appearance, content and behaviour of a component when using a macro, for example, changing the text.

Some options are required for the macro to work; these are marked as “Required” in the option description.

If you’re using Nunjucks macros in production with `html` options, or ones ending with `html`, you must sanitise the HTML to protect against [cross-site scripting exploits](https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting).

| Name | Type | Description |
| :--- | :--- | :---------- |
| **headingLevel** | integer | Heading level, from `1` to `6`. Default is `2`. |
| **classes** | string | Classes to add to the related navigation. |
| **attributes** | object | HTML attributes (for example data attributes) to add to the related navigation. |
| **sections** | array | An array of sections within the related navigation. See [sections](#options-for-sections). |

### Options for sections

| Name | Type | Description |
| :--- | :--- | :---------- |
| **title** | string | The title text that displays above the list of navigation links. Default is `Related content`. |
| **id** | string | ID attribute to add to the section container. |
| **items** | array | **Required**. An array of navigation links within the section. See [items](#options-for-items). |
| **subsections** | array | An array of sub-sections within the section. See [subsections](#options-for-subsections). |

### Options for subsections

| Name | Type | Description |
| :--- | :--- | :---------- |
| **title** | string | The title text that displays above the list of navigation links. |
| **id** | string | ID attribute to add to the subsection container. |
| **items** | array | **Required**. An array of navigation links within the section. See [items](#options-for-items). |

### Options for items

| Name | Type | Description |
| :--- | :--- | :---------- |
| **text** | string | **Required**. Text of the navigation link. |
| **href** | array | **Required**. The value of the navigation link’s `href` attribute for an navigation item. |

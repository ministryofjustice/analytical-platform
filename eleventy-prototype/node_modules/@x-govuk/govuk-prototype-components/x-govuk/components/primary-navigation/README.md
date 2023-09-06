# Primary navigation

Implements the primary navigation component used on the GOV.UK Design System website.

## Example usage

```njk
{{ xGovukPrimaryNavigation({
  visuallyHiddenTitle: "Navigation",
  items: [{
    text: "About this project",
    href: "/about"
  }, {
    text: "Contact us",
    href: "/contact"
  }]
}) }}
```

## Component options

Use options to customise the appearance, content and behaviour of a component when using a macro, for example, changing the text.

Some options are required for the macro to work; these are marked as “Required” in the option description.

If you’re using Nunjucks macros in production with `html` options, or ones ending with `html`, you must sanitise the HTML to protect against [cross-site scripting exploits](https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting).

| Name | Type | Description |
| :--- | :--- | :---------- |
| **items** | array | **Required**. An array of navigation links within the side navigation. See [items](#options-for-items). |
| **classes** | string | Classes to add to the primary navigation container. |
| **attributes** | object | HTML attributes (for example data attributes) to add to the primary navigation container. |
| **visuallyHiddenTitle** | string | A hidden title for the side navigation. |

### Options for items

| Name | Type | Description |
| :--- | :--- | :---------- |
| **text** | string | **Required**. Text of the navigation link. |
| **href** | array | **Required**. The value of the navigation link’s `href` attribute. |
| **current** | boolean | Indicate that the item is the current page. |
| **classes** | string | Classes to add to the navigation item. |

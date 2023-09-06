# Sub navigation

Implements the sub navigation component used on the GOV.UK Design System website.

## Example usage

```njk
{{ xGovukSubNavigation({
  visuallyHiddenTitle: "Navigation",
  items: [{
    text: "About this project",
    href: "/about"
  }, {
    text: "Contact us",
    href: "/contact",
    current: true,
    parent: true,
    children: [{
      text: "By email",
      href: "/contact/email"
    }, {
      text: "By telephone",
      href: "/contact/telephone"
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
| **items** | array | **Required**. An array of navigation links within the sub navigation. See [items](#options-for-items). |
| **classes** | string | Classes to add to the related navigation. |
| **attributes** | object | HTML attributes (for example data attributes) to add to the related navigation. |
| **visuallyHiddenTitle** | string | A hidden title for the sub navigation. |

### Options for items

| Name | Type | Description |
| :--- | :--- | :---------- |
| **text** | string | **Required**. Text of the navigation link. |
| **href** | array | **Required**. The value of the navigation link’s `href` attribute. |
| **current** | boolean | Indicate that the item is the current page. |
| **parent** | boolean | Indicate if the item is a parent. Use when the current item or any of its children are active. |
| **theme** | string | A name to group items by. If several navigation items share the same theme, they will appear together under that name. |
| **children** | string | An array of items as child navigation links. See [children](#options-for-children). |

### Options for children

| Name | Type | Description |
| :--- | :--- | :---------- |
| **text** | string | **Required**. Text of the navigation link. |
| **href** | array | **Required**. The value of the navigation link’s `href` attribute. |
| **current** | boolean | Indicate that the item is the current page. |

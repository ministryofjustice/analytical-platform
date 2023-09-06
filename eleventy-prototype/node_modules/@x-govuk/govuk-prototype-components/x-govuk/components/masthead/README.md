# Masthead

The masthead component is based on the component used on [GOV.UK product pages](https://github.com/alphagov/product-page-example).

This component may be useful if you are prototyping product or marketing pages.

## Example usage

```njk
{{ xGovukMasthead({
  classes: "x-govuk-masthead--large",
  phaseBanner: {
    text: "This is a new service"
  },
  breadcrumbs: {
    items: [{
      href: "/",
      text: "Home"
    }]
  },
  title: {
    text: "Design your service using GOV.UK styles, components and patterns"
  },
  description: {
    text: "Use this design system to make your service consistent with GOV.UK. Learn from the research and experience of other service teams and avoid repeating work that’s already been done."
  },
  startButton: {
    href: "/get-started/"
  },
  image: {
    src: "/images/homepage-illustration.svg"
  }
}) }}
```

## Component options

Use options to customise the appearance, content and behaviour of a component when using a macro, for example, changing the text.

Some options are required for the macro to work; these are marked as “Required” in the option description.

If you’re using Nunjucks macros in production with `html` options, or ones ending with `html`, you must sanitise the HTML to protect against [cross-site scripting exploits](https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting).

| Name | Type | Description |
| :--- | :--- | :---------- |
| **classes** | string | Classes to add to the masthead container. |
| **attributes** | object | HTML attributes (for example data attributes) to add to the masthead. |
| **title** | object | Title text shown in the masthead. See [title](#options-for-title). |
| **description** | object | Description text shown in the masthead. See [description](#options-for-description). |
| **startButton** | object | Options for start button. See [startButton](#options-for-startButton). |
| **image** | object | Options for image displayed on the right of the masthead on desktop layouts. See [image](#options-for-image). |
| **phaseBanner** | object | Options for the phase banner component. See [phase banner component](https://design-system.service.gov.uk/components/phase-banner/) in the GOV.UK Design System. |
| **breadcrumbs** | object | Options for the breadcrumbs component. See [breadcrumbs component](https://design-system.service.gov.uk/components/breadcrumbs/) in the GOV.UK Design System. |
| **caller** | nunjucks-block | Not strictly a parameter but [Nunjucks code convention](https://mozilla.github.io/nunjucks/templating.html#call). Using a `call` block enables you to call a macro with all the text inside the tag. This is helpful if you want to pass a lot of content into a macro. To use it, you will need to wrap the entire masthead component in a `call` block. Content called this way appears between the breadcrumbs (if present) and the title. |

### Options for title

| Name | Type | Description |
| :--- | :--- | :---------- |
| **text** | string | The title text that displays in the masthead. You can use any string with this option. If you set `title.html`, this option is not required and is ignored. |
| **html** | string | The title HTML that displays in the masthead. You can use any string with this option. Use this option to set text that contains HTML. If you set `title.html`, the `title.text` option is ignored. |

### Options for description

| Name | Type | Description |
| :--- | :--- | :---------- |
| **text** | string | The description text that displays in the masthead. You can use any string with this option. If you set `description.html`, this option is not required and is ignored. |
| **html** | string | The description HTML that displays in the masthead. You can use any string with this option. Use this option to set text that contains HTML. If you set `description.html`, the `description.text` option is ignored. |

### Options for startButton

| Name | Type | Description |
| :--- | :--- | :---------- |
| **text** | string | **Required**. If `startButton.html` is set, this is not required. Text for the button or link. If html is provided, the text argument will be ignored and element will be automatically set to button unless href is also set, or it has already been defined. This argument has no effect if element is set to input. |
| **html** | string | **Required**. If `startButton.text` is set, this is not required. HTML for the button or link. If `startButton.html` is provided, the text argument will be ignored and element will be automatically set to button unless `href` is also set, or it has already been defined. This argument has no effect if element is set to input. |
| **name** | string | Name for the `button`. This has no effect on `a` elements. |
| **type** | string | Type of `button` – `button`, `submit` or `reset`. Defaults to `submit`. This has no effect on `a` elements. |
| **href** | string | The URL that the button should link to. If this is set, element will be automatically set to `a`.
| **classes** | string | Classes to add to the button component.
| **attributes** | object | HTML attributes (for example data attributes) to add to the button component.

### Options for image

| Name | Type | Description |
| :--- | :--- | :---------- |
| **src** | string | URL of image displayed on the right of the masthead on desktop layouts. |
| **alt** | array | Alternative text for image. |

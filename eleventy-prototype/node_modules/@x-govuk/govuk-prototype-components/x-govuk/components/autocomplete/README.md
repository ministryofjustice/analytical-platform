# Autocomplete

The autocomplete component implements the [Accessible autocomplete pattern](https://github.com/alphagov/accessible-autocomplete) to enhance a fixed list of options provided by a `<select>` element.

This component may be useful if you want users to pick from a number of options. Unlike an autosuggest component, this component will only allow users to choose from a predetermined list of options.

## Example usage

```njk
{{ xGovukAutocomplete({
  id: "country",
  name: "country",
  allowEmpty: false,
  label: {
    classes: "govuk-label--l",
    isPageHeading: true,
    text: "Pick a country"
  },
  items: [
    { text: "Austria" },
    { text: "Belgium" },
    { text: "Bulgaria" },
    { text: "Croatia" },
    { text: "Republic of Cyprus" },
    { text: "Czech Republic" },
    { text: "Denmark" },
    { text: "Estonia" },
    { text: "Finland" },
    { text: "France" },
    { text: "Germany" },
    { text: "Greece" },
    { text: "Hungary" },
    { text: "Ireland" },
    { text: "Italy" },
    { text: "Latvia" },
    { text: "Lithuania" },
    { text: "Luxembourg" },
    { text: "Malta" },
    { text: "Netherlands" },
    { text: "Poland" },
    { text: "Portugal" },
    { text: "Romania" },
    { text: "Slovakia" },
    { text: "Slovenia" },
    { text: "Spain" },
    { text: "Sweden" }
  ]
}) }}
```

## Component options

Use options to customise the appearance, content and behaviour of a component when using a macro, for example, changing the text.

Some options are required for the macro to work; these are marked as “Required” in the option description.

If you’re using Nunjucks macros in production with `html` options, or ones ending with `html`, you must sanitise the HTML to protect against [cross-site scripting exploits](https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting).

| Name | Type | Description |
| :--- | :--- | :---------- |
| **id** | string | **Required.** ID for each autocomplete. |
| **name** | string | **Required.** Name property for the autocomplete. |
| **items** | array | **Required.** Array of option items for the autocomplete. See [items](#options-for-items). |
| **allowEmpty** | boolean | Whether to allow no answer to be given. Default is `false`. |
| **autoselect** | boolean | Whether to highlight the first option when the user types in something and receives results. Pressing enter will select it. Default is `false`. |
| **displayMenu** | string | Specify the way the menu should appear, whether `inline` or as an `overlay`. Default is `inline`. |
| **minLength** | number | The minimum number of characters that should be entered before the autocomplete will attempt to suggest options. When the query length is under this, the aria status region will also provide helpful text to the user informing them they should type in more. Default is `0`. |
| **showAllValues** | boolean | Whether all values are shown when the user clicks the input. This is similar to a default select menu, so the autocomplete is rendered with a dropdown arrow to convey this behaviour. Default is `false`. |
| **showNoOptionsFound** | boolean | Whether to display a ‘No results found’ message when there are no results. Default is `true`. |
| **describedBy** | string | One or more element IDs to add to the `aria-describedby` attribute, used to provide additional descriptive information for screenreader users. |
| **label** | object | Label text or HTML by specifying value for either text or html keys. See [label](#options-for-label). |
| **hint** | object | Options for the hint component. See [hint](#options-for-hint). |
| **errorMessage** | object | Options for the error message component. The error message component will not display if you use a falsy value for `errorMessage`, for example `false` or `null`. See [errorMessage](#options-for-errormessage). |
| **formGroup** | object | Options for the form-group wrapper. See [formGroup](#options-for-formgroup). |
| **classes** | string | Classes to add to the autocomplete. |
| **attributes** | object | HTML attributes (for example data attributes) to add to the select. |

### Options for items

| Name | Type | Description |
| :--- | :--- | :---------- |
| **value** | string | Value for the option item. Defaults to an empty string. |
| **text** | string | **Required**. Text for the option item. |
| **selected** | boolean | Sets the option as the selected. |
| **disabled** | boolean | Sets the option item as disabled. |
| **attributes** | object | HTML attributes (for example data attributes) to add to the option. |

### Options for formGroup

| Name | Type | Description |
| :--- | :--- | :---------- |
| **classes** | string | Classes to add to the form group (for example to show error state for the whole group). |

### Options for label

| Name | Type | Description |
| :--- | :--- | :---------- |
| **text** | string | **Required**. If `html` is set, this is not required. Text to use within the label. If `html` is provided, the `text` argument will be ignored. |
| **html** | string | **Required**. If `text` is set, this is not required. HTML to use within the label. If `html` is provided, the `text` argument will be ignored. |
| **for** | string | The value of the `for` attribute, the ID of the input the label is associated with. |
| **isPageHeading** | boolean | Whether the label also acts as the heading for the page. |
| **classes** | string | Classes to add to the label tag. |
| **attributes** | object | HTML attributes (for example data attributes) to add to the label tag. |

### Options for hint

| Name | Type | Description |
| :--- | :--- | :---------- |
| **text** | string | **Required**. If `html` is set, this is not required. Text to use within the hint. If `html` is provided, the `text` argument will be ignored. |
| **html** | string | **Required**. If `text` is set, this is not required. HTML to use within the hint. If `html` is provided, the `text` argument will be ignored. |
| **id** | string | Optional ID attribute to add to the hint span tag. |
| **classes** | string | Classes to add to the hint span tag. |
| **attributes** | object | HTML attributes (for example data attributes) to add to the hint span tag. |

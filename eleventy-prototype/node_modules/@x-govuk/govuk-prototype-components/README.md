# GOV.UK Prototype Components · [![test](https://github.com/x-govuk/govuk-prototype-components/actions/workflows/test.yml/badge.svg)](https://github.com/x-govuk/govuk-prototype-components/actions/workflows/test.yml)

GOV.UK Prototype Components contains the code you need to use common or experimental components that are not yet in the GOV.UK Design System.

These components are currently experimental and more research is needed to validate them.

| Component | Description |
| - | - |
| [xGovukAutocomplete](https://x-govuk.github.io/govuk-prototype-components/autocomplete/) | Implements the [Accessible autocomplete pattern](https://github.com/alphagov/accessible-autocomplete) to enhance a fixed list of options provided by a `<select>` element. |
| [xGovukMasthead](https://x-govuk.github.io/govuk-prototype-components/masthead/) | Implements the masthead component [used on many GOV.UK product pages](https://github.com/alphagov/product-page-example). |
| [xGovukPrimaryNavigation](https://x-govuk.github.io/govuk-prototype-components/primary-navigation/) | Implements the primary navigation component used on the GOV.UK Design System website. |
| [xGovukRelatedNavigation](https://x-govuk.github.io/govuk-prototype-components/related-navigation/) | Implements [related navigation component](https://components.publishing.service.gov.uk/component-guide/related_navigation) found in the `govuk_publishing_components` gem. |
| [xGovukSubNavigation](https://x-govuk.github.io/govuk-prototype-components/sub-navigation/) | Implements the sub navigation component used on the GOV.UK Design System website. |

Two JavaScript-only modules are also provided:

| Module | Description |
| - | - |
| [Edge](https://x-govuk.github.io/govuk-prototype-components/edge/) | Define the edges of your prototype for research. |
| [Warn on unsaved changes](https://x-govuk.github.io/govuk-prototype-components/warn-on-unsaved-changes/) | Warn users if they try to leave a page without saving changes to a form. |

> **Note** Prior to v1.0.0, this project included a collection of decorated form components. These can now be found in the [`govuk-decorated-components`](https://github.com/x-govuk/govuk-decorated-components) package.

## Requirements

Node.js v16 or later.

## Installation

```shell
npm install @x-govuk/govuk-prototype-components
```

## Usage with the GOV.UK Prototype Kit

GOV.UK Prototype Components are designed to work with the GOV.UK Prototype Kit.

If you are using v13 or later of the kit, the components will be immediately available once you have installed the package, and can be [managed alongside other plugins in your prototype](https://prototype-kit.service.gov.uk/docs/install-and-use-plugins).

## Advanced usage

If you are using an earlier version of the GOV.UK Prototype Kit, or only want to install selected components, you can do so by following the instructions below.

### CSS

To import all the Sass rules from GOV.UK Prototype Components, add the following to your Sass file:

```scss
@import "node_modules/@x-govuk/govuk-prototype-components/x-govuk/all";
```

You can also import Sass rules for an individual component. For example, to import styles for the masthead component, add the following to your Sass file:

```scss
@import "node_modules/@x-govuk/govuk-prototype-components/x-govuk/components/masthead/masthead";
```

### JavaScript

To import the JavaScript for the GOV.UK Prototype Components, you can either:

* add the GOV.UK Prototype Components JavaScript file to your HTML
* import the JavaScript using a bundler like [Webpack](https://webpack.js.org/)

#### Add the JavaScript file to your HTML

If you decide to add the JavaScript to your HTML, first either:

* set up your routing so that requests for the JavaScript file are served from `node_modules/@x-govuk/govuk-prototype-components/x-govuk/all.js`
* copy the `node_modules/@x-govuk/govuk-prototype-components/x-govuk/all.js` file into your application

Then import the JavaScript file before the closing `</body>` tag of your HTML page or page template, and run the `initAll` function to initialise all the components.

```html
<body>
  ...
  <script src="<YOUR-APP>/<YOUR-JS-FILE>.js"></script>
  <script>
    window.GOVUKPrototypeComponents.initAll()
  </script>
</body>
```

#### Import JavaScript using ES modules

If you decide to import using a bundler, use `import` to import all GOV.UK Prototype Components, then run the `initAll` function to initialise them:

```js
import { initAll } from '@x-govuk/govuk-prototype-components'

initAll()
```

You can also import the JavaScript for an individual component. For example, to import the autocomplete component, add the following to your JavaScript file:

```js
import { Autocomplete } from '@x-govuk/govuk-prototype-components'

const myAutocomplete = document.querySelector('#my-autocomplete')
new Autocomplete(myAutocomplete).init()
```

#### Import JavaScript using Common JS

If you’re using a bundler that uses CommonJS (like [Browserify](http://browserify.org/)), use `require`:

```js
const GOVUKPrototypeComponents = require('@x-govuk/govuk-prototype-components')

GOVUKPrototypeComponents.initAll()
```

It is not possible to import individual components using CommonJS.

## Contribute

The project repository is public and anyone can contribute.

[View this project on GitHub](https://github.com/x-govuk/govuk-prototype-components).

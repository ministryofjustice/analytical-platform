# markdown-it-govuk · [![test](https://github.com/x-govuk/markdown-it-govuk/actions/workflows/test.yml/badge.svg)](https://github.com/x-govuk/markdown-it-govuk/actions/workflows/test.yml)

Plugin for [markdown-it](https://github.com/markdown-it/markdown-it) to convert Markdown into GOV.UK Frontend-compliant HTML, inspired by its Ruby equivalent gem [`govuk_markdown`](https://github.com/DFE-Digital/govuk_markdown). If you are using the [marked](https://marked.js.org/) parser, use [`govuk-markdown`](https://github.com/x-govuk/govuk-markdown).

Don’t confuse this package with [govspeak](https://github.com/alphagov/govspeak), which is a Markdown dialect specifically built for the GOV.UK publishing system (www.gov.uk).

## Requirements

Node.js v16 or later.

## Installation

`npm install markdown-it-govuk --save`

## Usage

```js
const md = require('markdown-it')

md.use(require('markdown-it-govuk'))
```

The generated HTML will include the classes from GOV.UK Frontend. For example:

```js
md.render('[A link](/foo)')
```

Will output:

```html
<p class="govuk-body"><a class="govuk-link" href="/foo">A link</a></p>
```

### Code highlighting

Fenced code blocks can he highlighted using the supplied `highlight` function:

```js
const md = require('markdown-it')({
  highlight: require('markdown-it/highlight')
});


md.use(require('markdown-it-govuk'))
```

For example:

```js
md.render('```js\nconsole.log(\'Hello, World!\')\n```')
```

Will output:

```html
<pre class="x-govuk-code x-govuk-code--block" tabindex="0">
  <code class="x-govuk-code__language--js">
    <span class="x-govuk-code__variable">console</span>.<span class="x-govuk-code__title">log</span>(<span class="x-govuk-code__string">'Hello, World!'</span>)
  </code>
</pre>
```

To provide styling for inline and block code, add the following to your Sass file:

```scss
@import "markdown-it-govuk/x-govuk/all";
```

## Options

| Name | Type | Description |
| - | - | - |
| `headingsStartWith` | `string` | Heading size to use for the top-level heading (`xl` or `l`). Default is `l`. |
| `calvert` | `boolean \| Array` | Typographic improvements to enable (in addition to those provided by markdown-it’s `typographer` option). Set this option to `true` to enable all improvements, or array containing individual improvement sets to include (choose from `fractions`, `guillemets` and `mathematical`). Default is `false`. |

### Heading sizes

Headings start with `govuk-heading-l` for an `<h1>`, `govuk-heading-m` for an `<h2>` and so on. But change it if your pages feel unbalanced – the heading class you use does not always need to correspond to the heading level.

To start pages with `govuk-heading-xl` for an `<h1>`, `govuk-heading-l` for an `<h2>`, and so on, set the `headingsStartWith` option to `xl`:

```js
md.use(require('markdown-it-govuk'), {
  headingsStartWith: 'xl'
})

marked('# Heading\n## Heading 2')
```

Will output:

```html
<h1 class="govuk-heading-xl">Heading 1</h1>
<h2 class="govuk-heading-l">Heading 2</h2>
```

### Typographic improvements

In addition to the typographic replacements provided by markdown-it’s `typographer` option, you can enable a number of other glyphs present in Margaret Calvert’s GDS Transport font using the `calvert` option.

For example:

```js
md.use(require('markdown-it-govuk'), {
  calvert: ['fractions', 'mathematical']
})

marked('1/2 x 1/2 = 1/4')
```

Will output the following text, with the common fractions and correct multiplication symbol:

```html
<p class="govuk-body">½ × ½ = ¼</p>
```

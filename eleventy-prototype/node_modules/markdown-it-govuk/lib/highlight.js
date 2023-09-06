const highlightJs = require('highlight.js')
highlightJs.configure({ classPrefix: 'x-govuk-code__' })

module.exports = function (string, language) {
  if (language) {
    // Code language has been set, or can be determined
    let code
    if (highlightJs.getLanguage(language)) {
      code = highlightJs.highlight(string, { language }).value
    } else {
      code = highlightJs.highlightAuto(string).value
    }
    return `<pre class="x-govuk-code x-govuk-code--block x-govuk-code__language--${language}" tabindex="0"><code>${code}</code></pre>\n`
  } else {
    // No language found, so render as plain text
    return `<pre class="x-govuk-code x-govuk-code--block" tabindex="0">${string}</pre>\n`
  }
}

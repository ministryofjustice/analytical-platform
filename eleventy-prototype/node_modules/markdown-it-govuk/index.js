/**
 * Get default renderer for given markdown-it rule.
 *
 * @param {function} md markdown-it instance
 * @param {string} rule Rule to modify
 * @returns {function} Renderer for the given rule
 */
const getDefaultRenderer = (md, rule) => {
  return md.renderer.rules[rule] || function (tokens, idx, options, env, self) {
    return self.renderToken(tokens, idx, options)
  }
}

/**
 * Add classes to a token’s class attribute in given markdown-it rule.
 *
 * @param {function} md markdown-it instance
 * @param {string} rule Rule to modify
 * @param {string} classes Classes to add to the rule’s token
 * @returns {function} Renderer for the given rule
 */
const addClassesToRule = (md, rule, classes) => {
  const defaultRenderer = getDefaultRenderer(md, rule)
  md.renderer.rules[rule] = (tokens, idx, options, env, self) => {
    const token = tokens[idx]

    if (token.attrGet('class')) {
      token.attrJoin('class', classes)
    } else {
      token.attrPush(['class', classes])
    }

    return defaultRenderer(tokens, idx, options, env, self)
  }
}

const defaultOptions = {
  headingsStartWith: 'l',
  calvert: false
}

/**
 * Adds GOV.UK typography classes to blockquotes, headings, paragraphs, links,
 * lists, section breaks and tables and updates references to local files in
 * links and images to friendly URLs.
 *
 * @param {function} md markdown-it instance
 * @param {object} pluginOptions Plugin options
 * @returns {function} markdown-it rendering rules
 */
module.exports = function plugin (md, pluginOptions = {}) {
  // Merge options
  pluginOptions = { ...defaultOptions, ...pluginOptions }

  // Headings
  const headingRenderer = getDefaultRenderer(md, 'heading_open')
  md.renderer.rules.heading_open = (tokens, idx, options, env, self) => {
    // Headings can start with either `xl` or `l` size modifier
    const { headingsStartWith } = pluginOptions
    const modifiers = [
      ...(headingsStartWith === 'xl' ? ['xl'] : []),
      'l',
      'm'
    ]
    const level = tokens[idx].tag.replace(/^h(:?\d{1}?)/, '$1')
    const modifier = modifiers[level - 1] || 's'
    tokens[idx].attrPush(['class', `govuk-heading-${modifier}`])
    return headingRenderer(tokens, idx, options, env, self)
  }

  // Block quotes
  addClassesToRule(md, 'blockquote_open', 'govuk-inset-text govuk-!-margin-left-0')

  // Block code (indented, not fenced)
  addClassesToRule(md, 'code_block', 'govuk-inset-text govuk-!-margin-left-0')

  // Inline code
  addClassesToRule(md, 'code_inline', 'x-govuk-code x-govuk-code--inline')

  // Paragraphs
  addClassesToRule(md, 'paragraph_open', 'govuk-body')

  // Links
  addClassesToRule(md, 'link_open', 'govuk-link')

  // Lists
  addClassesToRule(md, 'bullet_list_open', 'govuk-list govuk-list--bullet')
  addClassesToRule(md, 'ordered_list_open', 'govuk-list govuk-list--number')

  // Section break
  addClassesToRule(md, 'hr', 'govuk-section-break govuk-section-break--xl govuk-section-break--visible')

  // Tables
  addClassesToRule(md, 'table_open', 'govuk-table')
  addClassesToRule(md, 'thead_open', 'govuk-table__head')
  addClassesToRule(md, 'tbody_open', 'govuk-table__body')
  addClassesToRule(md, 'tr_open', 'govuk-table__row')
  addClassesToRule(md, 'th_open', 'govuk-table__header')
  addClassesToRule(md, 'td_open', 'govuk-table__cell')

  // Text replacements
  const defaultTextRenderer = getDefaultRenderer(md, 'text')
  md.renderer.rules.text = (tokens, idx, options, env, self) => {
    const { calvert } = pluginOptions

    const improveAll = !Array.isArray(calvert) && calvert === true
    const improveFractions = Array.isArray(calvert) && calvert.includes('fractions')
    const improveGuillemets = Array.isArray(calvert) && calvert.includes('guillemets')
    const improveMathematical = Array.isArray(calvert) && calvert.includes('mathematical')

    // Improve fractions
    if (improveAll || improveFractions) {
      tokens[idx].content = tokens[idx].content
        .replace(/(?<!\d)1\/2(?!\d)/g, '½')
        .replace(/(?<!\d)1\/3(?!\d)/g, '⅓')
        .replace(/(?<!\d)2\/3(?!\d)/g, '⅔')
        .replace(/(?<!\d)1\/4(?!\d)/g, '¼')
        .replace(/(?<!\d)3\/4(?!\d)/g, '¾')
    }

    // Improve guillemets
    if (improveAll || improveGuillemets) {
      tokens[idx].content = tokens[idx].content
        .replace(/<</g, '«')
        .replace(/>>/g, '»')
    }

    // Improve mathematical symbols
    if (improveAll || improveMathematical) {
      tokens[idx].content = tokens[idx].content
        .replace(/\+-/g, '±')
        .replace(/(?<= )x(?= )/g, '×')
        .replace(/(?<= )<=(?= )/g, '≤')
        .replace(/(?<= )=>(?= )/g, '≥')
    }

    return defaultTextRenderer(tokens, idx, options, env, self)
  }
}

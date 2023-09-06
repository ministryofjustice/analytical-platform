const humanise = (string) => {
  string = string.replace('/README', '').replace('/', '')
  string = string.replaceAll('-', ' ')
  string = string.trim().replace(/^\w/, (c) => c.toUpperCase())
  return string
}

const slugify = (string) => {
  string = string.replace('/README', '').replace('/', '')
  return string
}

module.exports = {
  layout: 'sub-navigation',
  tags: ['component'],
  eleventyComputed: {
    title: data => humanise(data.page.filePathStem),
    permalink: data => `${slugify(data.page.filePathStem)}/`
  },
  eleventyNavigation: {
    parent: 'GOV.UK Prototype Components'
  }
}

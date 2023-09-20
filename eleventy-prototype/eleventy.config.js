const govukEleventyPlugin = require('@x-govuk/govuk-eleventy-plugin')
const eleventyNavigationPlugin = require("@11ty/eleventy-navigation");

module.exports = function(eleventyConfig) {
  // Set custom variable to decide the path prefix as it is used in a couple of places.
  const _customPathPrefix = process.env.PATH_PREFIX ?? '';
  // Register the plugin
  eleventyConfig.addPlugin(govukEleventyPlugin, {
    fontFamily: 'roboto, system-ui, sans-serif',
    homeKey: 'Home',
    headingpermalinks: true,
    header: {
      organisationLogo: 'royal-arms',
      organisationName: 'MoJ',
      productName: 'Data Platform Hub',
      search: {
        label: 'Search',
        indexPath: '/search.json',
        sitemapPath: '/sitemap'
      }
    },
    footer: {
      meta: {
          items: [
          {
              href: _customPathPrefix+'/about/',
              text: 'About'
          },
          {
              href: _customPathPrefix+'/cookies/',
              text: 'Cookies'
          },
          {
              href: 'https://github.com/ministryofjustice/data-platform',
              text: 'GitHub'
          }
        ]
      }
  },
        stylesheets: ['/styles/base.css'],
  });
  
// Used for tag page generation
eleventyConfig.addFilter("getAllTags", collection => {
  let tagSet = new Set();
  for(let item of collection) {
      (item.data.tags || []).forEach(tag => tagSet.add(tag));
  }
  return Array.from(tagSet);
});

eleventyConfig.addFilter("filterTagList", function filterTagList(tags) {
  // Tags in array are ignored, no tag list page is generated for these
  return (tags || []).filter(tag => ["homepage"].indexOf(tag) === -1);
});

  eleventyConfig.addCollection("homepageLinks", function(collectionApi) {
    return collectionApi.getFilteredByGlob([
      "**/analytical-platform.md",
      "**/blog.md",
      "**/data-platform.md",
      "**/support.md",
      "**/tech-docs.md"]).sort(function(a, b) {
        return a.data.title.localeCompare(b.data.title); // sort by title ascending
      });
  });

  eleventyConfig.addCollection("getAllADRsOrderedByTitle", function(collectionApi) {
    return collectionApi.getFilteredByGlob("**/tech docs/ADRs/*.md").sort(function(a, b) {
        return a.data.title.localeCompare(b.data.title); // sort by title ascending
      });
  });

  eleventyConfig.addCollection("getAllBlogsOrderedByTitle", function(collectionApi) {
    return collectionApi.getFilteredByGlob("**/blog/*.md").sort(function(a, b) {
        return a.data.title.localeCompare(b.data.title); // sort by title ascending
      });
  });

eleventyConfig.addGlobalData("phaseBannerConfiguration", () => {
  return {
    tag: {
      text: "Discovery"
    },
    html: 'This service is in the Discovery phase. Development is subject to change.'
  }
});

eleventyConfig.addGlobalData('pathPrefix', _customPathPrefix);

  return {
    dataTemplateEngine: 'njk',
    htmlTemplateEngine: 'njk',
    markdownTemplateEngine: 'njk',
    dir: {
      // Use layouts from the plugin
      layouts: '../_includes/layouts',
      includes: '../_includes',
      input: 'docs'
    },
    pathPrefix: _customPathPrefix
  }
};
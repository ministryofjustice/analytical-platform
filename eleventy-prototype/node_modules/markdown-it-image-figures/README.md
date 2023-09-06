# Markdown IT Image Figures

<span class="markdown-it-image-figures-npmversion"><a href="https://npmjs.org/package/markdown-it-image-figures" title="View this project on NPM"><img src="https://img.shields.io/npm/v/markdown-it-image-figures.svg" alt="NPM version" /></a></span>
[![CI](https://github.com/Antonio-Laguna/markdown-it-image-figures/actions/workflows/ci.yml/badge.svg)](https://github.com/Antonio-Laguna/markdown-it-image-figures/actions/workflows/ci.yml)

Render images occurring by itself in a paragraph as `<figure><img ...></figure>`, similar to [pandoc's implicit figures](http://pandoc.org/README.html#images).

This module is a fork from [markdown-it-implicit-figures](https://github.com/arve0/markdown-it-implicit-figures) in which I wanted to introduce new features and make sure this was up to what the standard is today.

Example input:
```md
text with ![](img.png)

![](fig.png)

works with links too:

[![](fig.png)](page.html)
```

Output:
```html
<p>text with <img src="img.png" alt=""></p>
<figure><img src="fig.png" alt=""></figure>
<p>works with links too:</p>
<figure><a href="page.html"><img src="fig.png" alt=""></a></figure>
```


## Install

```
$ npm i markdown-it-image-figures
```

## Usage

```js
const md = require('markdown-it')();
const implicitFigures = require('markdown-it-image-figures');

md.use(implicitFigures);

const src = 'text with ![](img.png)\n\n![](fig.png)\n\nanother paragraph';
const res = md.render(src);

console.log(res);

/*
<p>text with <img src="img.png" alt=""></p>
<figure><img src="fig.png" alt=""></figure>
<p>another paragraph</p>
*/
```

### Options

- `dataType`: Set `dataType` to `true` to declare the `data-type` being wrapped,
  e.g.: `<figure data-type="image">`. This can be useful for applying a special
  styling for different kind of figures.

- `figcaption`: Set `figcaption` to `true` or `"title"` to use the title as a `<figcaption>` block after the image; set `figcaption` to `"alt"` to use the alt text as a `<figcaption>`. E.g.: `![This is an alt](fig.png "This is a title")` renders to

```html
<figure>
    <img src="fig.png" alt="This is an alt">
    <figcaption>This is a title</figcaption>
</figure>
```

- `tabindex`: Set `tabindex` to `true` to add a `tabindex` property to each figure, beginning at `tabindex="1"` and incrementing for each figure encountered. Could be used with [this css-trick](https://css-tricks.com/expanding-images-html5/), which expands figures upon mouse-over.

- `link`: Put a link around the image if there is none yet.

- `copyAttrs`: Copy attributes matching (RegExp or string) `copyAttrs` to `figure` element.

- `lazy`: Applies the `loading` attribute as `lazy`.

- `removeSrc`: Removes the source from the image and saves it on `data-src`.

Code like `![alt](fig.png)` renders to:

````html
<figure>
    <img alt="alt" src="fig.png" loading="lazy">
</figure>
````

You can override it for a single image with something like `![alt](fig.png){loading=eager}` which will generate the following markup:

````html
<figure>
    <img alt="alt" src="fig.png" loading="eager">
</figure>
````

- `classes`: Adds the classes to the list of classes the image might have.

- `async`: Adds the attribute `decoding="async"` to all images. As with `lazy` you should be able to undo this for singular images `![alt](fig.png){decoding=auto}`

## Web performance recommended settings

Recommended settings for web performance is as follows

```
{
  lazy: true,
  async: true
}
```

Which will add `loading="lazy"` and `decoding="async"` to all images. This can be changed per image as explained above so you can opt out for a image at the top if you'd like. This will work great for the majority of the browsers.

However, if you need to broad your browser support and ensure that old browsers get lazy loaded images, you should probably use this setting:

```js
md.use(implicitFigures, {
  lazy: true,
  removeSrc: true,
  async: true,
  classes: 'lazy'
});

const src = '![alt](fig.png)';
const res = md.render(src);

console.log(res);
/*
<figure>
    <img alt="alt" data-src="fig.png" class="lazy" loading="lazy" decoding="async">
</figure>
*/
```

Then you need to load something like [Lozad.js](https://github.com/ApoorvSaxena/lozad.js) and some script like [this](./lazy-example.js). You might want to customise the class on the attribute `classes` which get added to the `img` (for easy selector).

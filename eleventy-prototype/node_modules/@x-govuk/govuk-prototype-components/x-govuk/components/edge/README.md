# Edge

A javascript component to make it easy to define the edges of your prototype for research.

Any link that points to `#` will give a customisable warning when clicked, ‘Sorry this has not been built yet’.

Sometimes a prototype has:

- parts that have not been built
- parts that will not be built
- places you do not want people to explore during research

Rather than a link to a 404 page, or worse a broken link that seems to do nothing, this component stops the user and gives feedback about what has happened.

Researchers can let users click the link if they want to without fear of breaking the prototype, and once the message has shown there is an opportunity for a follow-up, ‘what did you expect to see when you clicked that link’?

## Example usage

Add the attribute, `data-module="edge"` to any element. Links within it that point to `#` will then give a warning when clicked.

Put the attribute on the body element for the component to work with all `#` links.

```html
<body data-module="edge">
  <a href="#">A link to somewhere that’s not been built</a>
</body>
```

## Component options

A link can include a `data-message` attribute to show a different message:

```html
<body data-module="edge">
  <a href="#" data-message="A custom message">
    A link to somewhere that’s not been built
  </a>
</body>
```

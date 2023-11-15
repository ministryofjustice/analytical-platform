# API documentation lambda

This lambda hosts the data platform API reference documentation.

The API is specified using [OpenAPI format](https://learn.openapis.org/)
in [src/var/task/swagger.json](src/var/task/swagger.json).

We are using [redoc](https://github.com/Redocly/redoc) to generate the docs.

## Running locally

If you have nodejs installed, you can preview the docs in redoc using:

```sh
npx @redocly/cli preview-docs src/var/task/swagger.json
```

The [swagger editor](https://editor.swagger.io/) is also quite useful for
validating and changing the spec, although it will render slightly differently
to redoc.

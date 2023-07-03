<!-- markdownlint-disable MD003 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0]

### Changed

- Changed the SerializationLibrary in serdeinfo of glue table metadata from
`LazySimpleSerDe` to `OpenCSVSerde`
- `infer_glue_schema()` changed so null columns are typed as `string` not `null`
- The csv bytes value in `infer_glue_schema()` now decodes using uft-8-sig encoding
as byte order marks were persisting in some data

## [0.1.1] - 2023-09-30

###

- Added `registries` key to ECR login

## [0.1.0] - 2023-09-30

###

- Update workflows and image

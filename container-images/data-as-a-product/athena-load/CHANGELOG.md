<!-- markdownlint-disable MD003 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.2] - 2023-06-22

### Changed

- Changed the SerializationLibrary in serdeinfo of glue table metadata from
LazySimpleSerDeto OpenCSVSerde
- `infer_glue_schema()` changed so null columns are typed as string before
- the csv value now decodes using uft-8-sig encoding as byte order marks were
persisting in some data (likely csv created in windows)

## [0.0.1] - 2023-06-21

### Added

- Initial image as a proof-of-concept

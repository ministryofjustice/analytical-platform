<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] 2023-10-13

### Changed

- Bump base image to 4.0.0. This includes refactoring of the handler
  to use the new `DataProductMetadata` methods in data_product_metadata.

## [1.0.7] 2023-10-11

### Changed

- Bump base image to 2.2.0

## [1.0.6] 2023-10-03

### Changed

- update lambda response codes to match [aws example](https://github.com/awsdocs/aws-doc-sdk-examples/blob/main/python/example_code/lambda/lambda_handler_rest.py)

## [1.0.5] 2023-09-18

### Changed

- Added unit tests

## [1.0.4] 2023-09-15

### Changed

- Use new version of base image logging module within `daap-create-metadata`

## [1.0.3]

### Changed

- How the lambda handler gets the json metadata, passed to the API endpoint
  by the user, from the event arg.

## [1.0.2]

### Added

- logging of event passed to lambda function.

## [1.0.1]

- No real change but need to comply with workflow to
  get image deployed

## [1.0.0]

### Added

- Initial container definition

<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.6] 2023-10-11

### Added

- Logging of event object in handler

## [1.2.5] 2023-10-09

### Changed

- Deserialised event body parameter in handler
- String validation error response message to include reference to filename
- Filepath assertion to include file extension value

### Added

- Obtain filename from the event body in handler
- Perform String instance validation of filename
- Define file_extension string type variable from filename using
  `PurePath(filename).suffix`
- Perform empty string validation check for file_extension
- Pass file_extension to `element.raw_data_path` method to build
  the file path with the file extension.
- Defined the filename parameter in appropriate tests and pass
  the value into the event body dict
- Pass filename as parameter in event body in appropriate tests
- Added `test_invalid_file_extension()` to test for the presence of a file
  extension in the filename parameter

## [1.2.4] 2023-10-03

### Changed

- removed database and table querystring parameters
- created data-product-name & table-name variables from event body pathParameters
- created body variable from event.body json string
- replaced references to database with data-product-name
- replaced references to table with table-name

## [1.2.3]

### Changed

- Use new version of base image paths module

## [1.2.2] 2023-09-15

### Changed

- Use new version of base image logging module within `daap-presigned-url`

## [1.2.1]

### Changed

- Use shared library to construct S3 paths

## [1.2.0]

### Changed

- Use custom logging library image
- Use custom logging library

## [1.1.1] 2023-08-30

### Changed

- Switched to Modernisation Platform's OIDC role

## [1.1.0]

### Changed

- Upon requesting an upload URL, check to see if the database has a
  corresponding data product.
- Add 400, 404 responses
- Reinstate md5 hash check

## [1.0.2]

### Changed

- Excluding from Dependabot

## [1.0.1]

### Changed

- Bumped botocore and boto3 versions

## [1.0.0]

### Added

- Initial container definition

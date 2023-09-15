<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

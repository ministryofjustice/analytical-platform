<!-- markdownlint-disable MD003 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.2]

### Changed

- Bump base image to pick up logging changes

## [1.1.1]

### Changed

- Return a 400 error if required parameters are missing
- Return a 404 error if the table does not exist in the Glue catalog
- Ensure Content-Type header is set to 'application/json'.

## [1.1.0]

### Changed

- Use custom logging library image
- Use custom logging library

## [1.0.4] 2023-08-30

### Changed

- Switched to Modernisation Platform's OIDC role

## [1.0.3]

### Changed

- Excluding from Dependabot

## [1.0.2]

### Changed

- Bumped botocore and boto3 versions

## [1.0.1]

### Changed

- Bumped python version to 3.11
- Bumped botocore and boto3 versions

## [1.0.0]

### Added

- Initial container definition

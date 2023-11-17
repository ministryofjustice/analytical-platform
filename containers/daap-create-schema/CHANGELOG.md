<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2023-11-16

### Changed

- updated `create_schema` to use versioning module

## [1.2.0]

### Changed

- Update to base image 6.2.0

## [1.1.1]

### Changed

- fix error response if "schema" key missing in POST
- update Dockerfile COPY command fixing `LAMBDA_TASK_ROOT` typo

## [1.1.0]

### Added

- Call to push-to-catalogue lambda.

## [1.0.2]

### Changed

- Added missing validation for table name.

## [1.0.1]

### Changed

- Fix to incorrect name in config. No changes to actual lambda code.

## [1.0.0]

### Added

- Initial container definition

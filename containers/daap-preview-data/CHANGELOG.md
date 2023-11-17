<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.0] - 2023-11-15

### Changed

- Updated base image to 7.0.0

## [2.1.1] - 2023-11-15

### Changed

- Update to use versioned database names

## [2.1.0] - 2023-11-13

### Changed

- Updated base image to 6.2.0

## [2.0.2] - 2023-11-013

### Added

- structlog==23.2.0 to requirments.txt

## [2.0.1] - 2023-11-08

### Changed

- Fix malformed response format

## [2.0.0] - 2023-11-08

### Changed

- Return `text/plain` responses instead of `application/json`
- Update Dockerfile COPY command fixing `LAMBDA_TASK_ROOT` typo

## [1.0.2] - 2023-11-06

### Changed

- Added extra functionality to test data product

## [1.0.1] - 2023-11-03

### Changed

- Changed the name of ecr repository to push image

## [1.0.0]

### Added

- Initial container definition

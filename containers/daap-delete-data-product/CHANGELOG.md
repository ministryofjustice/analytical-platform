<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.0] 2023-11-23

### Changed

- python base version in Dockerfile to 7.3.1

## [2.1.0] 2023-11-21

### Changed

- `delete_data_product.handler` now deletes databases
    for all major versions of the data product

## [2.0.0] 2023-11-16

### Added

- `handler` now handles the entire process of removing data product

### Removed

- duplicated tests

## [1.3.1] - 2023-11-16

### Changed

- renamed VersionCreator to VersionManager to match versioning module

## [1.3.0] 2023-11-15

### Changed

- Update base image to 7.0.0

## [1.2.0] 2023-11-14

### Removes

- Unused boto clients

## [1.1.0] 2023-11-14

### Changed

- Use v6.3.1 of python base

## [1.0.0]

### Added

- Initial container definition

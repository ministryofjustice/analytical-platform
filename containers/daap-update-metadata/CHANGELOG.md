<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1] - 2023-11-16

### Changed

- renamed VersionCreator to VersionManager to match versioning module

## [1.1.0] - 2023-11-13

- update base image to 6.2.0
- update Dockerfile COPY command fixing `LAMBDA_TASK_ROOT` typo

## [1.0.1]

### Changed

- Return a 400 response when data product doesn't exist

## [1.0.0]

### Added

- Initial container definition

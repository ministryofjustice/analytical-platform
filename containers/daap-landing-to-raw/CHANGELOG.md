<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0]

### Changes

- Reject CSVs with embedded newlines. We are currently unable to process these
  CSVs, so the ingestion fails in the athena load step. This changes ensures
  that we handle the failure gracefully until we implement a solution (e.g.
  preprocessing the data).

## [1.2.0]

- Delete file from landing after copying it to raw

## [1.1.1]

- Dependency update

## [1.1.0]

- Add schema validation.
  If validation fails, data is moved to a "fail" location instead of "raw".

## [1.0.2]

- Bump patch to trigger image reupload

## [1.0.1]

- Bump patch to trigger image reupload

## [1.0.0]

### Added

- Initial container definition

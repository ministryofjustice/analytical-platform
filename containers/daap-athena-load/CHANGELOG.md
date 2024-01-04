<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Renamed `extraction_timestamp` to `load_timestamp`
- Update base image to 8.0.0

## [2.0.0] 2023-11-21

- Moved internal classes to base image (7.3.0)

## [1.5.0] 2023-11-15

- Updated base image to 7.0.0

## [1.4.0] 2023-11-13

- Updated base image to 6.2.0

## [1.3.2] 2023-11-10

### Changed

- Updated base image
- Updated pyarrow

## [1.3.1] 2023-11-08

### Changed

- Updated base image
- Updated pip
- Updated urllib3

## [1.3.0] 2023-11-02

### Updated

- load handler attempts to load existing schema for creation of the curated table,
  falling back to inferred metadata if none is found
- curated database name includes major version

## [1.2.4] 2023-11-6

### Changed

- `athena_load_handler_test.py` updated s3 client reference to `s3_client`

## [1.2.3] 2023-10-18

### Changed

- Base image to daap-python-base:3.2.0

## [1.2.2] 2023-10-11

### Changed

- Bumped `urllib3` from 1.26.16 to 1.26.17

## [1.2.1] 2023-10-02

### Changed

- Base image to daap-python-base:2.2.0

## [1.2.0] 2023-09-29

### Changed

- Removed infer_glue_schema to daap-python-base image. This version won't
  work, but version 1.2.1 will shortly follow including new base image.

## [1.1.5] 2023-09-26

### Changed

- Refactor infer_glue_schema
- Remove unused argument from create_raw_athena_table
- Ensure raw athena tables are deleted if there is an exception
- Bump base image version
- If curated table is missing when ingesting data for an existing data product,
  we now throw a 500 error. This should not normally happen, and if it does
  we can run reload_data_product to fix it.

## [1.1.4] 2023-09-21

### Changed

- The temporary raw athena table is created with a unique name per invocation
- Use new version of base image paths module

## [1.1.4] 2023-09-15

### Changed

- Use new version of base image logging module within `daap-athena-load`

## [1.1.3] 2023-09-13

### Changed

- Use `data_platform_paths` from the base image for s3 paths and athena table names

## [1.1.2] 2023-08-30

### Changed

- Switched to Modernisation Platform's OIDC role

## [1.1.1]

### Changed

- Code refactored into several files.
- Added comments

## [1.1.0]

### Changed

- Uses new base image daap-python-base:0.3.0, which includes intial version of the
  custom logger.
- DataPlatformLogger has been implemented, creating log entries to the stdout and
  a queryable json file.
- infer_glue_schema() has been improved to better infer data types for a sample of
  csv data.

## [1.0.5]

### Changed

- Excluding from Dependabot

## [1.0.4]

### Changed

- Bumped botocore, boto3, fsspec, parameterized, and pyarrow versions

## [1.0.3]

### Changed

- Bumped python version to 3.11
- Bumped botocore and boto3 versions

## [1.0.2]

### Added

- `image_version` to lambda code, applied as env var inside container in v1.0.1

### Changed

- the keys to get the bucket and key from the event passed to the lambda from eventbridge
  as the event rule have changed slightly.

## [1.0.1]

### Added

- `VERSION` variable now available inside container

## [1.0.0]

### Changed

- Changed the SerializationLibrary in serdeinfo of glue table metadata from
  `LazySimpleSerDe` to `OpenCSVSerde`
- `infer_glue_schema()` changed so null columns are typed as `string` not `null`
- The csv bytes value in `infer_glue_schema()` now decodes using uft-8-sig encoding
  as byte order marks were persisting in some data

## [0.1.1] - 2023-09-30

###

- Added `registries` key to ECR login

## [0.1.0] - 2023-09-30

###

- Update workflows and image

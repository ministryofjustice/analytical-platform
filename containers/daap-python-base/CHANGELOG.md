<!-- markdownlint-disable MD003 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2023-09-01

## Added

- data_product_metadata python module. This contains code that will be used, intially
by an api endpoint to create data product metadata, but in future, expanded to be used
in other endpoints too, such as an update_metadata endpoint.

## [0.3.0] - 2023-08-11

### Changed

- Fix GitHub Container Registry login

## [0.2.0] - 2023-08-11

### Changed

- Push image to GitHub Container Registry, so downstream builds can pull it

## [0.1.0]

###

- Initial image contains custom logging module in addition to python 3.11

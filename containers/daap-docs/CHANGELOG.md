<!-- markdownlint-disable MD003 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Fix parameter names for /preview endpoint
- update Dockerfile COPY command fixing `LAMBDA_TASK_ROOT` typo

## [1.0.12] 2023-11-09

### Changed

- apiKey security schema reference to authorizationToken
- upload data and delete table are now grouped under data
- update metadata is now a put request

## [1.0.11] 2023-11-07

### Changed

- upload data now reflects POST

### Removed

- references to deleteTable schema

## [1.0.10] 2023-11-07

### Added

- Documentation for `DELETE /data-product/{data-product-name}/table/{table-name}`

### Changed

- Documentation for `POST /data-product/{data-product-name}/table/{table-name}/upload`

## [1.0.9] 2023-11-06

### Added

- Documentation for `GET /data-product/{data-product-name}/table/{table-name}/preview`

## [1.0.8] 2023-10-25

### Added

- Documentation for `PUT /data-product/{data-product-name}/table/{table-name}/schema`

## [1.0.7] 2023-10-25

### Added

- Documentation for `PUT /data-product/{data-product-name}`

## [1.0.6] 2023-10-19

### Added

- Documentation for `/data-product/{data-product-name}/table/{table-name}/schema`
  GET endpoint.

## [1.0.5] 2023-10-16

### Updated

- Documentation for `/data-product/{data-product-name}/table/{table-name}/schema`
  endpoint.

## [1.0.4] 2023-09-09

### Updated

- Documentation for `/data-product/register` endpoint

## [1.0.3] 2023-09-07

### Added

- Documentation for `register_data_product` endpoint

## [1.0.2] 2023-08-30

### Changed

- Switched to Modernisation Platform's OIDC role

## [1.0.1]

### Changed

- Use Node.js version 14

## [1.0.0]

### Added

- Initial container definition

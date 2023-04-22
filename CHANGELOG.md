## [Unreleased]

## [0.1.0] - 2022-12-05

- Initial release

## [0.1.1] - 2022-12-06

- Adding support for headers and body

## [0.1.2] - 2022-12-10

- Adding support to URL parameters
- Adding logs to the framework activity
- Removing undefined Status Codes from http_status_code hash
- Moving methods from Macaw class to RequestDataFiltering module, respecting SOLID

## [0.1.3] - 2022-12-13

- Adding logger gem to Macaw class to fix a bug on the application start

## [0.1.4] - 2023-04-09

- Adding log by aspect on endpoint calls to improve observability
- Moving the server for a new separate class to respect single responsibility
- Improved the data filtering middleware to sanitize inputs

## [0.1.5] - 2023-04-16

- Adding support to path variables

## [0.2.0] - 2023-04-22

- Adding middleware for integration with Prometheus to collect metrics
- Adding a simple caching mechanism that can be enabled separately for each endpoint
- Performance and functional optimizations

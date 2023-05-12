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

## [1.0.0] - 2023-04-28

- Adding support to HTTPS/SSL using security certificates
- Implemented a middleware for rate limiting to prevent DoS attacks
- Improvement of caching strategy to ignore optional headers
- First production-ready version

## [1.0.1] - 2023-05-03

- Introducing server-side session management
- Fixing a bug with cache
- Improving README

## [1.0.2] - 2023-05-06

- Fixing a bug with cache where ignored_headers where not being properly loaded
- Fixed a bug with cache where URL parameters were not being considered in the strategy
- Updating SECURITY.md with more information

## [1.0.3] - 2023-05-10

- Fixing issue of error responses being cached
- Implementing support for min and max SSL version
- Creating log sanitization to prevent log forging

## [1.0.4] - 2023-05-11

- Fixing issue with response body returning always a blank line at the beginning

## [1.0.5] - 2023-05-12

- Fixing critical bug where threads were being killed and not respawning after abrupt client connection shutdown

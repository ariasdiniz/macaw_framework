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

## [1.1.0] - 2023-05-20

- Adding support for other SSL/TSL keys other than RSA
- New mechanism to handle server shutdown properly
- Improving log readability
- Automatic logging is now optional

## [1.1.1] - 2023-05-28

- Adding native cron jobs
- Documentation improvement

## [1.1.2] - 2023-05-31

- Fixing retry bug in cron jobs, where retries were made after an exception without waiting for interval
- Fixing another bug in cron jobs where an exception were thrown when start_delay were not set
- Documentation improvement

## [1.1.3] - 2023-05-31

- Adding start_without_server! method for starting the framework without running a web server
- Improving documentation
- Raising the number of default threads from 5 to 10

## [1.1.5] - 2023-07-04

- Improving number of virtual threads to 200.
- Fixing misleading description on ThreadServer.

## [1.1.6] - 2023-07-19

- Creating support for public folder

## [1.1.7] - 2023-08-12

- Fixing a bug where the server would not start with the public folder feature enabled on non-Unix systems

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

## [1.1.8] - 2023-09-17

- Optimizing bug report template on GitHub
- Optimizing return clause of the get_files_public_folder method

## [1.2.0] - 2023-10-05

- Fixing bug where the server would accept new connections during shutdown

## [1.2.1] - 2023-11-06

- Simplifying logging aspect for readability

## [1.2.2]

- Including possibility of setting port, bind and threads programmatically

## [1.2.3]

- Fixing import of pathname

## [1.2.4]

- Fixing small bug on lof during endpoint declaration
- Disclosing security issue on session storage

## [1.2.5]

- Improvements to cache usability

## [1.2.6]

- Improving session strategy and fixing vulnerabilities on it.

## [1.3.0]
- Improvements to cache usability
- Improving session strategy and fixing vulnerabilities on it
- Fixed a bug where errors were being logged with level INFO
- Improved error stack trace

## [1.3.1]
- Fixing bug where missing session configuration on `application.json` break the application
- Including a Cache module for manual caching.

## [1.3.21]
- Refactoring shutdown method
- Fixing a bug where a HTTP call without client data broke the parser
- Removing logs registering new HTTP connections to reduce log bloat

## [1.3.22]
- Fixing error with tests on Ruby 3.4.x due to splash operator

## [1.4]
- Add missing dependencies for Ruby 4.x

## [1.4.1] - 2026-02-01
- Fixing issue when re-spawning new threads

## [1.4.2] - 2026-02-24
- Removing unused Rate Limiting Middleware

## [1.4.3] - 2026-03-04
- Fix critical bug in `sanitize_parameter_value` where the first `gsub` result was discarded, leaving special characters unsanitized
- Fix header parsing regex to correctly accept real-world headers (Authorization, Cookie, User-Agent, Host with port, etc.)
- Fix deadlock in `maintain_worker_pool` caused by non-reentrant mutex re-acquisition when respawning dead workers
- Add missing `require 'digest'` in `LogDataFilter`, preventing `NameError` when sensitive fields are configured
- Fix thread-safety in `Cache#write` and `Cache#read`: both now always synchronize on the internal mutex
- Fix thread-safety of `@session` hash: `declare_client_session` now synchronizes on a dedicated mutex
- Fix `**kwargs` being silently dropped in `LoggingAspect` and `PrometheusAspect` when forwarding to `super`
- Fix `CacheAspect` holding mutex during entire endpoint execution on cache miss; endpoint now runs outside the lock
- Remove blocking `sleep(2)` from `MemoryInvalidationMiddleware` constructor; eviction thread no longer halts server startup
- Remove `sleep(1)` per cron job from `CronRunner#start_cron_job_thread`; startup is no longer O(N) seconds
- Remove dead code in `CronRunner`: duplicate `start_delay ||= 0` and always-true `unless start_delay.nil?` guard
- Make `application.json` path configurable via `MACAW_CONFIG` env var; rescue `Errno::ENOENT` and `JSON::ParserError` with graceful fallback
- Remove broken SSL2 and SSL3 from `SupportedSSLVersions` (POODLE/DROWN, unavailable on modern OpenSSL)
- `LoggingAspect` now logs request params, body, and response status on every endpoint call
- Use `Process.clock_gettime(Process::CLOCK_MONOTONIC)` in `PrometheusAspect` instead of `Time.now` for accurate duration measurement
- Fix Prometheus `/metrics` endpoint `Content-Type` to `text/plain; version=0.0.4; charset=utf-8`
- Fix RFC 7230 non-compliance: remove stray space before `\r\n` in HTTP status line
- Add eviction thread error rescue in `MemoryInvalidationMiddleware` to prevent silent thread death
- Set `frozen_string_literal: true` consistently across all library files
- Implement HTTP keep-alive: persistent TCP connections now reuse the same socket for multiple requests without a new handshake
- Add configurable per-connection read timeout (default 30 s, configurable via `keep_alive_timeout` in `application.json`) to prevent idle or faulty clients from holding worker threads indefinitely
- Server now responds with `Connection: keep-alive` or `Connection: close` headers according to the client's request
- Fix request parser to properly detect client EOF and raise `EOFError` instead of propagating `nil` through the parsing pipeline

## [1.5.0] - 2026-03-04
- Use `IO#timeout=` (Ruby 3.2+) for socket timeout with `SO_RCVTIMEO` fallback for older Ruby and SSL sockets
- Remove Prometheus integration: `PrometheusAspect`, `PrometheusMiddleware`, and `prometheus-client` gem dependency removed
- Remove built-in session management: `declare_client_session`, `set_session`, `@session`, and all related configuration removed
- Remove `CronRunner` and `setup_job`: periodic job scheduling is no longer a responsibility of the framework; use a dedicated job library instead
- Remove `start_without_server!` method, which existed solely to support cron-only deployments
- Handle SIGTERM for graceful shutdown in containerised deployments; SIGTERM now triggers the same shutdown path as SIGINT
- Add `Content-Length: 0` to inline 404 and 500 error responses for RFC 7230 compliance
- Change default `bind` from `'localhost'` to `'0.0.0.0'` so the server is reachable in containers without explicit configuration
- Sanitize `\r` and `\n` from response header keys and values to prevent HTTP response splitting attacks
- Add configurable request body size limit (`max_body_size` in `application.json`, default 1 MB); requests exceeding the limit are rejected with 413 Content Too Large before the body is read
- Fix `maintain_worker_pool` iteration bug: `each_with_index` + `delete_at` skipped elements after a deletion; replaced with `reject!` + bulk respawn
- Fix cache TTL fallback: `nil.to_i` returned 0 when `cache_invalidation` was absent, silently creating a zero-TTL cache; replaced with safe navigation `&.to_i || 3_600`
- Fix `CacheAspect` crash when endpoint returns `nil`: guard added before `response[1]` access
- Replace `sanitize_parameter_value` character stripping with proper CGI URL-decoding (preserves emails, UUIDs, decimal values)
- Broaden HTTP version pattern in request parser from `HTTP/1.1` literal to regex — HTTP/1.0 requests now route correctly
- Add `rescue StandardError` guard in `Cache#invalidation_process` to prevent silent background eviction-thread death
- Fix `ThreadServer#shutdown` poison-pill count: uses actual `@workers.size` instead of `@num_threads`
- Add C extension scaffold (`ext/macaw_framework_ext/`) as a foundation for future native performance-sensitive routines

## [1.5.1]- 2026-06-07
- Fix an error when running the server on Ruby 4.0.5 on MacOS that default values for status and headers on the response were not being set when these values are implicit on method declaration

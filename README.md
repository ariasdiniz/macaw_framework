[![Gem Version](https://badge.fury.io/rb/macaw_framework.svg)](https://badge.fury.io/rb/macaw_framework) ![CI Pipeline](https://github.com/ariasdiniz/macaw_framework/actions/workflows/main.yml/badge.svg?branch=main)
# MacawFramework

MacawFramework is a lightweight, easy-to-use web framework for Ruby designed to simplify the development of small to 
medium-sized web applications. With support for various HTTP methods, caching, and session management, MacawFramework 
provides developers with the essential tools to quickly build and deploy their applications.

- [MacawFramework](#macawframework)
    * [Features](#features)
    * [Installation](#installation)
    * [Performance](#performance)
    * [Compatibility](#compatibility)
    * [MacawFramework's Built-In Web Server](#macawframeworks-built-in-web-server)
    * [Usage](#usage)
        + [Basic routing: Define routes with support for GET, POST, PUT, PATCH, and DELETE HTTP methods](#basic-routing-define-routes-with-support-for-get-post-put-patch-and-delete-http-methods)
        + [Caching: Improve performance by caching responses and configuring cache invalidation](#caching-improve-performance-by-caching-responses-and-configuring-cache-invalidation)
        + [Session management: Handle user sessions securely with server-side in-memory storage](#session-management-handle-user-sessions-securely-with-server-side-in-memory-storage)
        + [Configuration: Customize various aspects of the framework through the application.json configuration file, such as rate limiting, SSL support, and Prometheus integration](#configuration-customize-various-aspects-of-the-framework-through-the-applicationjson-configuration-file-such-as-rate-limiting-ssl-support-and-prometheus-integration)
        + [Monitoring: Easily monitor your application performance and metrics with built-in Prometheus support](#monitoring-easily-monitor-your-application-performance-and-metrics-with-built-in-prometheus-support)
        + [Routing for "public" Folder: Serve Static Assets](#routing-for-public-folder-serve-static-assets)
        + [Periodic Jobs](#periodic-jobs)
        + [Tips](#tips)
    * [Contributing](#contributing)
    * [License](#license)
    * [Code of Conduct](#code-of-conduct)

## Features

- Simple routing with support for GET, POST, PUT, PATCH, and DELETE HTTP methods
- Caching middleware for improved performance
- Session management with server-side in-memory storage
- Basic rate limiting and SSL support
- Prometheus integration for monitoring and metrics
- Lightweight and easy to learn

## Installation

Install the gem and add it to the application's Gemfile by executing:

    $ bundle add macaw_framework

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install macaw_framework

## Performance

We evaluated MacawFramework (Version 1.2.0) to assess its ability to handle simultaneous requests under heavy load. Disabling non-essential features, such as cache and logging, we observed remarkable results. The framework demonstrated efficient memory usage (243.3 MB average) and handled an impressive 600,000 HTTP requests with an average response time of just 1 millisecond. Throughput reached an outstanding 10,196.45 requests per second. These findings suggest that MacawFramework is well-equipped to handle substantial HTTP traffic without significant performance degradation. For detailed results, please refer to the [full report](https://github.com/ariasdiniz/macaw_performance_test).

## Compatibility

MacawFramework is built to be highly compatible, since it uses only native Ruby code:

- **MRI**: MacawFramework is compatible with Matz's Ruby Interpreter (MRI), version 2.7.0 and onwards. If you are using this version or a more recent one, you should not encounter any compatibility issues.

- **TruffleRuby**: TruffleRuby is another Ruby interpreter that is fully compatible with MacawFramework. This provides developers with more flexibility in their choice of Ruby interpreter.

- **JRuby**: MacawFramework is also compatible with JRuby, a version of Ruby that runs on the Java Virtual Machine (JVM).

## MacawFramework's Built-In Web Server

MacawFramework includes a built-in web server based on Ruby's TCPServer class, providing a lightweight yet robust solution for serving your web applications. It incorporates features such as SSL security and a thread-based architecture, offering a balance of simplicity, performance, and robustness.

### Key Features

- **SSL Security**: Our server integrates SSL security, offering secure communication for your applications. By providing a valid SSL context, the built-in TCPServer will be wrapped in OpenSSL's SSLServer, adding an essential secure transport layer to your web server.

- **Thread-based Architecture**: We employ a thread-based model where a specified number of worker threads are used to handle client connections. Incoming connections are queued in a work queue, where they are then processed by the worker threads, ensuring fair scheduling and load distribution.

- **Thread Pool Management**: We make use of Ruby's built-in synchronization constructs, using a Mutex to safely manage the worker threads pool. A maintenance routine periodically checks the health of the worker threads, respawning any that have died, ensuring consistent server performance.

- **Graceful Shutdown**: Our server is designed to gracefully shut down when required, making sure all pending connections in the work queue are processed before closing the worker threads and the server itself. This ensures that no client requests are abruptly terminated, providing a smooth user experience.

It's worth noting that while our threading model is simple and effective, it has some limitations. The number of concurrent connections it can handle is limited by the number of worker threads, and it could be susceptible to slow clients, which could tie up a worker thread and reduce the server's capacity. However, for JRuby and TruffleRuby users, this threading model can leverage true system-level threading due to the lack of a Global Interpreter Lock (GIL), potentially providing better performance on multi-core systems and handling larger numbers of concurrent connections more efficiently.

Despite these trade-offs, MacawFramework's built-in web server offers a good balance for most web applications, particularly for small to medium scale deployments. For larger-scale applications with high concurrency demands, consider supplementing the built-in server with an event-driven architecture or utilizing a third-party server solution better suited for such scenarios.

In summary, MacawFramework's built-in web server provides a straightforward, efficient, and secure solution for running your web applications, requiring minimal configuration and making deployment a breeze.

## Usage

### Basic routing: Define routes with support for GET, POST, PUT, PATCH, and DELETE HTTP methods

```ruby
require 'macaw_framework'

m = MacawFramework::Macaw.new

m.get('/hello_world') do |_context|
  return "Hello, World!", 200, {"Content-Type" => "text/plain"}
end

m.post('/submit_data/:path_variable') do |context|
  context[:body] # Client body data
  context[:params] # Client params, like URL parameters or variables
  context[:headers] # Client headers
  context[:params][:path_variable] # The defined path variable can be found in :params
  context[:client] # Client session
end

m.start!
```

### Caching: Improve performance by caching responses and configuring cache invalidation

```ruby
m = MacawFramework::Macaw.new

m.get('/cached_data', cache: ["header_to_cache", "query_param_to_cache"]) do |context|
  # Retrieve data
end
```

*Observation: To activate caching, you also have to set its properties in the `application.json` file. If you don't, the caching strategy will not work. See the Configuration section below for more details.*

### Session management: Handle user sessions with server-side in-memory storage

Session will only be enabled if it's configurations exists in the `application.json` file.
The session mechanism works by recovering the Session ID from a client sent header. The default
header is `X-Session-ID`, but it can be changed in the `application.json` file.

This header will be sent back to the user on every response if Session is enabled. Also, the
session ID will be automatically generated and sent to a client if this client does not provide
a session id in the HTTP request. In the case of the client sending an ID of an expired session
the framework will return a new session with a new ID.

```ruby
m = MacawFramework::Macaw.new

m.get('/login') do |context|
  # Authenticate user
  context[:client][:user_id] = user_id
end

m.get('/dashboard') do |context|
  # Check if the user is logged in
  if context[:client][:user_id]
    # Show dashboard
  else
    # Redirect to login
  end
end
```

### Configuration: Customize various aspects of the framework through the application.json configuration file, such as rate limiting, SSL support, and Prometheus integration

```json
{
  "macaw": {
    "port": 8080,
    "bind": "localhost",
    "threads": 200,
    "cache": {
      "cache_invalidation": 3600
    },
    "prometheus": {
      "endpoint": "/metrics"
    },
    "rate_limiting": {
      "window": 10,
      "max_requests": 3
    },
    "ssl": {
      "min": "SSL3",
      "max": "TLS1.3",
      "key_type": "EC",
      "cert_file_name": "path/to/cert/file/file.crt",
      "key_file_name": "path/to/cert/key/file.key"
    },
    "session": {
      "secure_header": "X-Session-ID",
      "invalidation_time": 3600
    }
  }
}
```

### Monitoring: Easily monitor your application performance and metrics with built-in Prometheus support

```shell
curl http://localhost:8080/metrics
```

### Routing for "public" Folder: Serve Static Assets

MacawFramework allows you to serve static assets, such as CSS, JavaScript, images, etc., through the "public" folder. 
To enable this functionality, make sure the "public" folder is placed in the same directory as the main.rb file. 
The "public" folder should contain any static assets required by your web application.

To avoid issues, instantiate the Macaw using the `dir` property as following:

```ruby
MacawFramework::Macaw.new(dir: __dir__)
```

By default, MacawFramework will automatically serve files from the "public" folder recursively when matching requests 
are made. For example, if you have an image file named "logo.png" inside a "img" folder in the "public" folder, it will 
be accessible at http://yourdomain.com/img/logo.png without any additional configuration.

#### Caution: This is incompatible with most non-unix systems, such as Windows. If you are using a non-unix system, you will need to manually configure the "public" folder and use dir as nil to avoid problems.

### Periodic Jobs

Macaw Framework supports the declaration of periodic jobs right in your application code. This feature allows developers to
define tasks that run at set intervals, starting after an optional delay. Each job runs in a separate thread, meaning
your periodic jobs can execute in parallel without blocking the rest of your application.

Here's an example of how to declare a periodic job:

```ruby
m = MacawFramework::Macaw.new

m.setup_job(interval: 5, start_delay: 5, job_name: "cron job 1") do
  puts "i'm a periodic job that runs every 5 secs!"
end
```

Values for interval and start_delay are in seconds.

**Caution: Defining a lot of jobs with low interval can severely degrade performance.**

If you want to build an application with just cron jobs, that don't need to run a web server, you can start
MacawFramework without running a web server with the `start_without_server!` method, instead of `start!`.

### Tips

- The automatic logging and log aspect are now optional. To disable them, simply start Macaw with `custom_log` set to nil.

```ruby
MacawFramework::Macaw.new(custom_log: nil)
```

- Cache invalidation time should be specified in seconds. In order to enable caching, The `application.json` file
  should exist in the app main directory and it needs the `cache_invalidation` config set. It is possible to
  provide a list of strings in the property `ignore_headers`. All the client headers with the same name as any
  of the strings provided will be ignored from the caching strategy. This is useful to exclude headers like
  correlation IDs from the caching strategy.

- URL parameters like `...endOfUrl?key1=value1&key2=value2` can be found in the `context[:params]`

```ruby
m = MacawFramework::Macaw.new

m.get('/test_params') do |context|
  context[:params]["key1"] # returns: value1
end
```

- You can also set `port`, `bind` and `threads` programmatically as shown below. This will override values set in the
`application.json` file

```ruby
m = MacawFramework::Macaw.new

m.port = 3000
m.bind = '0.0.0.0'
m.threads = 300
```

- The default number of virtual threads in the thread pool is 200.

- Rate Limit window should also be specified in seconds. Rate limit will be activated only if the `rate_limiting` config
  exists inside `application.json`.

- If the SSL configuration is provided in the `application.json` file with valid certificate and key files, the TCP server
  will be wrapped with HTTPS security using the provided certificate.

- The supported values for `min` and `max` in the SSL configuration are: `SSL2`, `SSL3`, `TLS1.1`, `TLS1.2`, and `TLS1.3`,
  and the supported values for `key_type` are `RSA` and `EC`.

- If Prometheus is enabled, a GET endpoint will be defined at path `/metrics` to collect Prometheus metrics. This path
  is configurable via the `application.json` file.

- The verb methods must always return a string or nil (used as the response), a number corresponding to the HTTP status
  code to be returned to the client, and the response headers as a Hash or nil. If an endpoint doesn't return a value or
  returns nil for body, status code, and headers, a default 200 OK status will be sent as the response.

- For cron jobs without a start_delay, a value of 0 will be used. For a job without a name, a unique name will be generated
  for it.

- Ensure the "public" folder is placed in the same directory as the main.rb file: The "public" folder should contain any static assets, 
  such as CSS, JavaScript, or images, that your web application requires. Placing it in the same directory as the main.rb file ensures 
  that the server can correctly serve these assets.

- Always run the main.rb file from a terminal in the same directory: To avoid any potential issues related to file paths and relative paths, 
  make sure to run the main.rb file from a terminal in the same directory where it is located. This will ensure that the application can access 
  the necessary files and resources without any problems.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ariasdiniz/macaw_framework. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ariasdiniz/macaw_framework/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MacawFramework project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/ariasdiniz/macaw_framework/blob/main/CODE_OF_CONDUCT.md).

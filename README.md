# MacawFramework

MacawFramework is a lightweight, easy-to-use web framework for Ruby designed to simplify the development of small to 
medium-sized web applications. With support for various HTTP methods, caching, and session management, MacawFramework 
provides developers with the essential tools to quickly build and deploy their applications.

## Features

- Simple routing with support for GET, POST, PUT, PATCH, and DELETE HTTP methods
- Caching middleware for improved performance
- Session management with server-side in-memory storage
- Basic rate limiting and SSL support
- Prometheus integration for monitoring and metrics
- Lightweight and easy to learn

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add macaw_framework

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install macaw_framework

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
  context[:params] # Client params, like url parameters or variables
  context[:headers] # Client headers
  context[:params][:path_variable] # The defined path variable can be found in :params
  context[:client] # Client session
end

m.start!

```

### Caching: Improve performance by caching responses and configuring cache invalidation

```ruby
m.get('/cached_data', cache: true) do |context|
# Retrieve data
end
```

Observation: To activate caching you also have to set it's properties on the application.json file. If you don't, caching strategy will not work.
See section below for configurations.

### Session management: Handle user sessions securely with server-side in-memory storage

```ruby
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
    "threads": 10,
    "log": {
      "max_length": 1024,
      "sensitive_fields": [
        "password"
      ]
    },
    "cache": {
      "cache_invalidation": 3600,
      "ignore_headers": [
        "header-to-be-ignored-from-caching-strategy",
        "another-header-to-be-ignored-from-caching-strategy"
      ]
    },
    "prometheus": {
      "endpoint": "/metrics"
    },
    "rate_limiting": {
      "window": 10,
      "max_requests": 3
    },
    "ssl": {
      "cert_file_name": "path/to/cert/file/file.crt",
      "key_file_name": "path/to/cert/key/file.key"
    }
  }
}
```

### Monitoring: Easily monitor your application performance and metrics with built-in Prometheus support

```shell
curl http://localhost:8080/metrics
```

### Tips

Cache invalidation time should be specified in seconds. In order to enable caching, The application.json file
should exist in the app main directory and it need the `cache_invalidation` config set. It is possible to
provide a list of strings in the property `ignore_headers`. All the client headers with the same name of any
of the strings provided will be ignored from caching strategy. This is useful to exclude headers like 
correlation IDs from the caching strategy.

URL parameters like `...endOfUrl?key1=value1&key2=value2` can be find in the `context[:params]`

```ruby
m.get('/test_params') do |context|
  context[:params]["key1"] # returns: value1
end
```

Rate Limit window should also be specified in seconds. Rate limit will be activated only if the `rate_limiting` config
exists inside `application.json`.

If the SSL configuration is provided in the `application.json` file with valid certificate and key files, the TCP server
will be wrapped with HTTPS security using the provided certificate.

If prometheus is enabled, a get endpoint will be defined at path `/metrics` to collect prometheus metrics. This path
is configurable via the `application.json` file.

The verb methods must always return a string or nil (used as the response), a number corresponding to the HTTP status 
code to be returned to the client and the response headers as a Hash or nil. If an endpoint doesn't return a value or 
returns nil for body, status code and headers, a default 200 OK status will be sent as the response.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ariasdiniz/macaw_framework. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ariasdiniz/macaw_framework/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MacawFramework project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ariasdiniz/macaw_framework/blob/main/CODE_OF_CONDUCT.md).

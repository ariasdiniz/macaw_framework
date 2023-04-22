# MacawFramework

<img src="macaw_logo.png" alt= “” style="width: 30%;height: 30%;margin-left: 35%">

This is a framework for developing web applications. Please have in mind that this is still a work in progress and
it is strongly advised to not use it for production purposes for now. Actually it supports only HTTP. and HTTPS/SSL
support will be implemented soon. Anyone who wishes to contribute is welcome.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add macaw_framework

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install macaw_framework

## Usage

The usage of the framework still very simple. Actually it support 5 HTTP verbs: GET, POST, PUT, PATCH and DELETE.

The default server port is 8080. To choose a different port, create a file with the name `application.json` 
in the same directory of the script that will start the application with the following content:

```json
{
  "macaw": {
    "port": 8080,
    "bind": "localhost",
    "threads": 10,
    "cache": {
      "cache_invalidation": 3600
    }
  }
}
```

Cache invalidation time should be specified in seconds. In order to enable caching, The application.json file
should exist in the app main directory and it need the `cache_invalidation` config set.

Example of usage:

```ruby
require 'macaw_framework'
require 'json'

m = MacawFramework::Macaw.new

m.get('/hello_world', cache: true) do |context|
  context[:body] # Returns the request body as string
  context[:params] # Returns query parameters and path variables as a hash
  context[:headers] # Returns headers as a hash
  return JSON.pretty_generate({ hello_message: 'Hello World!' }), 200, {"Content-Type" => "application/json"}
end

m.post('/hello_world/:path_variable') do |context|
  context[:body] # Returns the request body as string
  context[:params] # Returns query parameters and path variables as a hash
  context[:headers] # Returns headers as a hash
  context[:params][:path_variable] # The defined path variable can be found in :params
  return JSON.pretty_generate({ hello_message: 'Hello World!' }), 200
end

m.start!
```

The example above starts a server and creates a GET endpoint at localhost/hello_world.

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

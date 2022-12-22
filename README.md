# MacawFramework

This is a framework for developing web applications. Please have in mind that this is still a work in progress and
it is strongly advised to not use it for production purposes for now. Actualy it supports only HTTP. HTTPS and SSL
support will be implemented soon. Anyone who wishes to contribute is welcome.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add macaw_framework

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install macaw_framework

## Usage

The usage of the framework still very simple. Actually it support 5 HTTP verbs: GET, POST, PUT, PATCH and DELETE.
For now, the framework can't resolve client request body and headers. The support for this will be included soon.

The default server port is 8080. To choose a different port, create a file with the name `application.json` 
in the same directory of the script that will start the application with the following content:

```json
{
  "macaw": {
    "port": 80,
    "bind": "0.0.0.0"
  }
}
```

Example of usage:

```ruby
require 'macaw_framework'
require 'json'

m = MacawFramework::Macaw.new

m.get('/hello_world') do |headers, body, parameters|
  return JSON.pretty_generate({ hello_message: 'Hello World!' }), 200
end

m.start!
```

The above example will start a server and will create a GET endpoint at localhost/hello_world.

The verb methods must always return a String or nil (Used as response) and a number corresponding the 
HTTP Status Code to be returned to the client.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ariasdiniz/macaw_framework. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ariasdiniz/macaw_framework/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MacawFramework project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ariasdiniz/macaw_framework/blob/main/CODE_OF_CONDUCT.md).

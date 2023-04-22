# frozen_string_literal: true

require_relative "lib/macaw_framework/version"

Gem::Specification.new do |spec|
  spec.name = "macaw_framework"
  spec.version = MacawFramework::VERSION
  spec.authors = ["Aria Diniz"]
  spec.email = ["aria.diniz.dev@gmail.com"]

  spec.summary = "A web framework still in development."
  spec.description = "A project started for study purpose that I intend to keep working on."
  spec.homepage = "https://github.com/ariasdiniz/macaw_framework"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/macaw_framework"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ariasdiniz/macaw_framework"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "prometheus-client", "~> 4.1"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

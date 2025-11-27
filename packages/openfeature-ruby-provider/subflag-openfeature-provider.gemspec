# frozen_string_literal: true

require_relative "lib/subflag/version"

Gem::Specification.new do |spec|
  spec.name = "subflag-openfeature-provider"
  spec.version = Subflag::VERSION
  spec.authors = ["Subflag"]
  spec.email = ["support@subflag.com"]

  spec.summary = "OpenFeature provider for Subflag feature flag management"
  spec.description = "A Ruby provider for OpenFeature that integrates with Subflag's feature flag management system. Supports boolean, string, number, and object flag types with evaluation context."
  spec.homepage = "https://github.com/subflag/subflag"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/subflag/subflag/tree/main/sdk/packages/openfeature-ruby-provider"
  spec.metadata["changelog_uri"] = "https://github.com/subflag/subflag/blob/main/sdk/packages/openfeature-ruby-provider/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", ">= 2.0", "< 3.0"
  spec.add_dependency "openfeature-sdk", ">= 0.3", "< 1.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "webmock", "~> 3.18"
end

# frozen_string_literal: true

require_relative "lib/subflag/rails/version"

Gem::Specification.new do |spec|
  spec.name = "subflag-rails"
  spec.version = Subflag::Rails::VERSION
  spec.authors = ["Subflag"]
  spec.email = ["support@subflag.com"]

  spec.summary = "Typed feature flags for Rails - booleans, strings, numbers, and JSON"
  spec.description = "Feature flags for Rails with selectable backends. Use Subflag Cloud (SaaS), ActiveRecord (self-hosted), or Memory (testing). Get typed values (boolean, string, integer, double, object) with the same API regardless of backend."
  spec.homepage = "https://subflag.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/subflag/sdk"
  spec.metadata["changelog_uri"] = "https://github.com/subflag/sdk/blob/main/packages/subflag-rails/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://subflag.com/docs/ruby"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("{lib,sig}/**/*") + %w[LICENSE.txt README.md CHANGELOG.md]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  # Core OpenFeature SDK (always needed)
  spec.add_dependency "openfeature-sdk", ">= 0.3", "< 1.0"
  spec.add_dependency "railties", ">= 6.1"
  spec.add_dependency "actionview", ">= 6.1"

  # Note: subflag-openfeature-provider is lazily loaded and only required
  # when using backend: :subflag (Subflag Cloud). Users of :active_record
  # or :memory backends don't need it. If using Subflag Cloud, add to Gemfile:
  #   gem 'subflag-openfeature-provider', '~> 0.3'

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rails", "~> 2.19"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "rails", ">= 6.1"
end

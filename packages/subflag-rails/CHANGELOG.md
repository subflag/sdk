# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2025-11-30

### Changed

- Updated to use `OpenFeature::SDK::EvaluationContext` for proper context passing
- Requires `subflag-openfeature-provider` >= 0.1 (works best with 0.2+)

### Fixed

- Fixed OpenFeature SDK require path (`open_feature/sdk` instead of `openfeature/sdk`)
- Fixed provider class reference (`Subflag::Provider` instead of `Subflag::OpenFeature::Provider`)
- Fixed OpenFeature client method calls to use keyword arguments

## [0.1.0] - 2025-11-30

### Added

- Initial release
- `Subflag.flags` DSL with method_missing for clean flag access
- Boolean flags with `?` suffix (e.g., `flags.new_checkout?`)
- Typed value flags with required defaults
- `subflag_enabled?` and `subflag_value` helpers for controllers and views
- `subflag_for` helper to get a flag accessor
- Auto-scoping to `current_user` in controllers and views
- User context configuration for targeting
- Rails generator (`rails g subflag:install`)
- Auto-configuration from Rails credentials and ENV
- Bracket access for exact flag names
- `evaluate` method for full evaluation details
- Logging support with configurable levels

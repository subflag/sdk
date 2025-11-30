# Changelog

All notable changes to this project will be documented in this file.

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

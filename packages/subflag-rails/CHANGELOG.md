# Changelog

All notable changes to this project will be documented in this file.

## [0.5.1] - 2025-12-15

### Fixed

- **Admin UI not loading**: Include `app/` and `config/` directories in gem package
  - Previously only `lib/` was packaged, causing mounted Engine to fail

## [0.5.0] - 2025-12-11

### Added

- **Admin UI**: Mount at `/subflag` to manage flags visually
  - List, create, edit, and delete flags
  - Toggle flags enabled/disabled
  - Visual targeting rule builder (no JSON editing required)
  - Test rules against sample contexts
  - Configurable authentication via `config.admin_auth`
- **Targeting rules for ActiveRecord backend**: Return different values based on user attributes
  - 12 comparison operators: EQUALS, NOT_EQUALS, IN, NOT_IN, CONTAINS, NOT_CONTAINS, STARTS_WITH, ENDS_WITH, GREATER_THAN, LESS_THAN, GREATER_THAN_OR_EQUAL, LESS_THAN_OR_EQUAL, MATCHES
  - AND/OR condition groups
  - First-match evaluation order
- **TargetingEngine**: Evaluates rules against user context

### Changed

- `subflag_flags` table now includes `targeting_rules` column (JSON/JSONB)
- Generator creates migration with JSONB for PostgreSQL, JSON for other databases

## [0.4.0] - 2025-12-09

### Added

- **Selectable backends**: Choose where flags are stored
  - `:subflag` - Subflag Cloud (default)
  - `:active_record` - Self-hosted, flags in your database
  - `:memory` - In-memory for testing
- **ActiveRecord backend**: Store flags in `subflag_flags` table
- **Memory backend**: Programmatic flag management for tests
- Generator `--backend` option to configure storage

## [0.3.0] - 2025-12-07

### Added

- **Bulk flag evaluation**: `subflag_prefetch` helper fetches all flags in a single API call
- **Cross-request caching**: `config.cache_ttl` enables caching via `Rails.cache` with configurable TTL
- `Subflag.prefetch_flags` and `Subflag::Rails.prefetch_flags` module methods

### Changed

- Requires `subflag-openfeature-provider` >= 0.3.1

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

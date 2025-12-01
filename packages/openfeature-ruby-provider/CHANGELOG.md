# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2025-11-30

### Changed

- **Breaking**: Provider now returns `OpenFeature::SDK::Provider::ResolutionDetails` instead of plain Hash
- Added `require "open_feature/sdk"` for proper SDK integration

### Fixed

- Fixed compatibility with OpenFeature Ruby SDK 0.4.x

## [0.1.0] - 2025-11-30

### Added

- Initial release
- OpenFeature provider implementation for Subflag
- Support for boolean, string, integer, float, and object flag types
- Evaluation context support with targeting key
- Error handling with proper OpenFeature error codes
- Direct client usage without OpenFeature SDK

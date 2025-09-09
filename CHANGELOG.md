# Changelog

All notable changes to the Flutter PS App Shell project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.19] - 2025-09-09

### Added
- Enhanced datalog parsing with flexible attribute mapping system
- `diagnoseDatalogParsing()` method for debugging datalog issues
- Collection-specific attribute ID mappings
- Comprehensive diagnostic analysis in investigation screen
- DATALOG_PARSING_GUIDE.md documentation

### Fixed
- Critical bug where DatabaseService failed to parse InstantDB datalog format
- "0 documents returned" issue when data exists in datalog format
- Better handling of unmapped attribute IDs

### Improved
- Type inference for unmapped attributes (dates, emails, booleans)
- Detailed logging throughout datalog parsing
- Fallback strategies for unknown attribute IDs

## [0.7.18] - 2025-09-09

### Fixed
- Nullable callback type error in datalog investigation screen
- iOS build failure caused by VoidCallback? type mismatch

## [0.7.17] - 2025-09-09

### Changed
- Applied comprehensive dart format code style fixes
- Consistent formatting across 19 files
- Improved code readability and maintainability

## [0.7.16] - 2025-09-09

### Added
- InstantDB v0.2.1 upgrade for official datalog fixes
- Comprehensive datalog investigation screen
- Robust datalog-result parsing workaround
- DATALOG_WORKAROUND_REMOVAL_PLAN.md

### Changed
- Upgraded instantdb_flutter from ^0.1.1 to ^0.2.1

## [0.7.15] - 2025-09-07

### Fixed
- DialogController.dismiss() not working across all UI systems

## [0.7.14] - 2025-09-07

### Fixed
- DatabaseService race condition in query methods

## Previous Versions

For versions before 0.7.14, please refer to the git history and release tags.

## InstantDB Flutter Package Updates

### [instantdb_flutter 0.2.3] - External Package Update
- Fixed race condition in query execution
- Added comprehensive logging throughout datalog conversion
- Queries now return cached data immediately
- Proper datalog-to-collection format conversion
- No more "0 documents" issue when data exists

### [instantdb_flutter 0.2.1] - External Package Update  
- Initial fixes for datalog format handling
- Improved reactive query architecture
- Better connection timing management
# Changelog

All notable changes to the Flutter PS App Shell project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.22] - 2025-09-10

### Fixed
- **Critical Bug Resolution**: Fixed InstantDB validation failures by using direct values instead of $eq wrapping
- **Query Format Correction**: `findWhere` and `watchWhere` now match working `read` method behavior
- **Cache Pollution Eliminated**: Proper query format prevents validation errors that corrupt the cache

### Added
- Comprehensive InstantDB test screen (`/instantdb-test`) for reproducing and debugging query issues
- Test screen integrated into example app with science icon access button
- Enhanced debugging capabilities with real-time logging and cache pollution detection

### Changed
- `_transformWhereClause()` now preserves simple values directly (matches read method)
- Removed automatic `$eq` operator wrapping that caused validation failures
- Updated query transformation to only preserve existing operator maps

## [0.7.21] - 2025-09-09

### Fixed
- **Critical Bug**: Fixed malformed InstantDB queries in `findWhere` and `watchWhere` methods (incomplete fix)
- **Query Validation Errors**: Attempted to resolve InstantDB validation failures 
- **UI Display Issues**: Fixed collections appearing empty after navigation between items
- **Cache Corruption**: Attempted to eliminate cache pollution

### Added
- `_transformWhereClause()` helper method to format InstantDB operators (incorrect implementation)
- Comprehensive test for operator transformation in database service tests
- Documentation updates explaining the query format fix

### Changed
- `findWhere` now uses proper `{'$': {'where': transformedWhere}}` query structure
- `watchWhere` now uses proper `{'$': {'where': transformedWhere}}` query structure  
- Simple equality values automatically wrapped with `$eq` operator (this caused the issue)
- Existing operator maps preserved (backward compatible)

## [0.7.20] - 2025-09-09

### Changed
- Updated documentation to reflect InstantDB Flutter v0.2.4 improvements
- Added notes about entity type resolution fixes in external package

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

### [instantdb_flutter 0.2.4] - External Package Update (Latest)
**Fix Entity Type Resolution - Completes the datalog conversion fix trilogy**
- Fixed entities being cached under wrong collection name
- Queries for 'conversations' no longer return 0 documents when entities lack __type field
- Proper entity type detection from response data['q'] field
- Correct cache key resolution - entities cached under query type instead of 'todos'
- Smart grouping with proper fallback chain through conversion pipeline

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
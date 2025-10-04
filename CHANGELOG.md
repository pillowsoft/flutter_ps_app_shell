# Changelog

All notable changes to the Flutter PS App Shell project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.6] - 2025-10-03

### Fixed
- **Dark Mode Detection on Physical Devices**: Fixed CupertinoApp not responding to theme mode changes on physical iOS devices. The `getCurrentBrightness()` method now properly creates a signal dependency by reading `themeMode.value`, ensuring the Watch rebuilds when theme changes.

### Added
- **Text Scale Factor Clamping**: Added `maxTextScaleFactor` parameter to `AppConfig` (defaults to 1.3) to prevent extreme iOS Accessibility 'Larger Text' settings (up to 310%) from making the app unusable. The app now wraps in MediaQuery to clamp textScaleFactor between 1.0 and the configured maximum.

### Technical Details
- Added `maxTextScaleFactor: 1.3` parameter to `AppConfig` class
- Wrapped CupertinoApp/MaterialApp in MediaQuery to apply text scale clamping
- Fixed signal reactivity in `getCurrentBrightness()` by explicitly reading `themeMode.value` before switch statement
- Text scale clamping applies to all UI systems (Material, Cupertino, ForUI)

## [1.0.5] - 2025-10-03

### Fixed
- **Nested Route Titles**: Fixed App Shell not resolving titles for nested/sub-routes. The `_getCurrentRouteTitle()` method now recursively searches the route tree instead of only doing exact path matching on flat routes.

### Added
- **Path Parameter Support**: Added `_pathMatches()` helper method to match route paths with parameters (e.g., `/detail/:level` matches `/detail/1`)
- **Parent Route Fallback**: When navigating to a sub-route path that doesn't match any sub-route exactly, the parent route's title is used as fallback

### Changed
- **Removed Hardcoded Workarounds**: Eliminated hardcoded special cases for navigation demo routes (`/navigation/detail/:level`, `/navigation/nested/:level`) in favor of general recursive solution

### Technical Details
- Replaced `_getCurrentRouteTitle()` with recursive implementation that traverses the route tree
- Sub-routes with relative paths (e.g., `detail/:level`) are now correctly resolved against parent paths (e.g., `/navigation`)
- Supports arbitrary nesting depth of sub-routes
- Example: Route `/mashup` with sub-route `video-selection` correctly resolves `/mashup/video-selection` to "Video Selection" title

## [1.0.4] - 2025-10-03

### Fixed
- **Back Button on Initial Launch**: Fixed back button incorrectly appearing on home page during initial app launch. Home page detection now handles empty string from GoRouter initial state.

### Technical Details
- Updated `isHomePage` logic to handle initial state: `isHomePage = currentPath == '/' || currentPath.isEmpty`
- On initial app launch, `routerState.uri.path` may return empty string before full GoRouter initialization

## [1.0.3] - 2025-10-03

### Fixed
- **Back Button on Home Page**: Fixed back button incorrectly appearing on home page (`/`) even when it shouldn't. Back button now explicitly excluded from home page.
- **Back Button Navigation to Home**: Fixed back button not working when clicked on Settings (or other top-level routes) in hidden navigation mode. Back button now correctly navigates to home page (`/`) when navigation is hidden and user is on a top-level route.

### Technical Details
- Changed `isNotHomePage` to `isHomePage` for clearer logic: `isHomePage = currentPath == '/'`
- Added explicit exclusion of home page: `shouldShowBackButton = !isHomePage && (...)`
- Added fallback navigation to home when `visibleRoutes.isEmpty` and on top-level route
- All UI systems (Material, Cupertino, ForUI) now use explicit back button with custom handler when navigation is hidden

## [1.0.2] - 2025-10-03

### Fixed
- **Back Button for Hidden Navigation**: Fixed issue where users could navigate to Settings (or other routes) when all navigation is hidden (`showInNavigation: false` on all routes) but couldn't navigate back to the home page. Back button now appears on all non-home routes when navigation is hidden, preventing users from getting stuck.

### Technical Details
- Added special case in `AppShell._buildAppBar` back button logic: `needsBackForHiddenNav = visibleRoutes.isEmpty && isNotHomePage`
- Back button detection now considers three conditions: `canPop || isNestedRoute || needsBackForHiddenNav`
- Enables fully programmatic navigation workflows where all routes are accessed via code rather than visible navigation UI

## [0.7.23] - 2025-09-11

### Fixed
- **Reactive Cycles Eliminated**: Removed problematic `effect()` calls from `watchCollection` and `watchWhere` methods that caused "Cycle detected" errors
- **ScaffoldMessenger Error**: Fixed runtime error in Cupertino mode by using adaptive `ui.showSnackBar()` instead of Material-specific API
- **Signal Dependencies**: Properly structured all signal operations to prevent circular dependencies
- **watchWhere Test**: Modified test to avoid reading computed signal values that trigger cycles

### Added
- **Copy Logs Button**: One-click log copying to clipboard in InstantDB test screen
- **Diagnostic Wrappers**: Added `_safeSignalRead()` method for debugging signal cycles with detailed error locations
- **Enhanced Logging**: Console logging with `[InstantDBTest]` prefix for better signal initialization visibility
- **Defensive Logging**: Added logging in `watchCollection` and `watchWhere` methods for debugging

### Changed
- **InstantDB Test Screen**: Now fully functional across all UI systems (Material, Cupertino, ForUI)
- **Error Handling**: Added graceful fallbacks when signal operations fail
- **Cross-Platform Notifications**: Proper platform-specific notification styling for all UI modes

### Technical Details
- Removed `realtimeUpdates.value++` from effect blocks that were causing immediate cycles
- Changed from `StatefulHookWidget` to `StatefulWidget` in test screen
- Replaced intermediate signal copying with direct computed values where appropriate
- Added `untracked()` wrapper for logging operations to prevent dependency creation

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
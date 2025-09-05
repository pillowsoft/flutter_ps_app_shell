# Changelog

## 0.7.7 - 2025-09-05

### Fixed
- **🐛 Sidebar Navigation Vertical Alignment**: Fixed sidebar/drawer navigation items being centered vertically instead of top-aligned
  - Added proper mainAxisAlignment.start to ensure items appear at top in both collapsed and expanded states
  - Wrapped expanded drawer content in Align widget with topLeft alignment for consistent positioning
  - Navigation items now consistently appear at the top of the sidebar/drawer in all states
- **🔧 Button Method Compilation Errors**: Fixed compilation errors in action_navigation_demo_screen.dart
  - Replaced non-existent filledButton method with button method
  - Updated button parameter from 'text' to correct 'label' parameter
  - Example app now compiles and runs without errors

## 0.7.3 - 2025-09-04

### Fixed
- **🐛 Service Registration Duplicate Checks**: Added defensive checks to prevent crashes when services are pre-registered
  - All 10 services now check `getIt.isRegistered<T>()` before registering
  - Enables pre-initialization for onboarding, auth checks, and testing scenarios
  - Apps no longer crash with "Type X is already registered inside GetIt" error
  - Clear logging indicates which services were skipped vs newly registered
  - Fully backward compatible with existing apps


## 0.7.2 - 2025-09-04

### Changed
- **💄 Improved CupertinoTabBar Icon Centering**: Added 4px top padding to tab bar icons for better visual balance
  - Icons now appear properly centered within the tab bar height
  - Equal spacing above and below creates a more polished appearance
  - Applies to both regular and active icon states
  - Fixes visual issue where icons appeared too close to the top edge


## 0.7.1 - 2025-09-04

### Fixed
- **🐛 Cupertino Bottom Navigation Priority**: Fixed critical bug where CupertinoWidgetFactory prioritized drawer over bottom navigation
  - Apps with ≤5 visible routes now correctly show bottom tabs on narrow screens
  - Reordered scaffold checks to evaluate bottomNavBar before drawer
  - Resolves issue where 3-route apps showed drawer instead of expected bottom navigation
- **📊 Enhanced Navigation Debugging**: Added comprehensive logging for navigation logic decisions
  - Logs screen width, route counts, and navigation type selection
  - Logs UI factory inputs to help troubleshoot platform-specific issues
  - Useful for debugging responsive navigation behavior


## 0.7.0 - 2025-09-04

### Added
- **🎯 Responsive Navigation Demo**: Comprehensive interactive demo screen at `/responsive-navigation` showing navigation threshold logic and hidden routes
- **📱 Hidden Routes Documentation**: Complete examples and use cases for workflow routes accessible via code but not shown in navigation

### Changed
- **⚡ Navigation Threshold Logic**: Updated to count only visible routes (`showInNavigation: true`) instead of all routes when determining navigation type
- **📖 Enhanced Documentation**: Updated README.md and CLAUDE.md with navigation fixes and hidden routes examples

### Fixed
- **🐛 Critical Navigation Bug**: Apps now correctly show bottom navigation when ≤5 visible routes (was incorrectly showing drawer when hidden routes pushed count >5)
- **🎮 Responsive Behavior**: Mobile apps with ≤5 visible routes now properly display bottom tabs instead of drawer navigation


## 0.6.0 - 2025-09-04

### Added
- **🚀 AppShellAction Navigation Context Enhancement**: Complete solution for clean navigation without service locators
  - **Declarative Route Navigation**: `AppShellAction.route()` for simple route-based navigation
  - **Context-Aware Navigation**: `AppShellAction.navigate()` with full BuildContext access
  - **Factory Constructors**: Clean, purpose-built constructors for different navigation patterns
- **Navigation Features**:
  - Automatic error handling with GoRouter fallback
  - Support for both `go` and `replace` navigation modes
  - Priority-based action handling (route > onNavigate > onPressed)
  - Enhanced logging for debugging navigation actions
- **Developer Experience**:
  - Comprehensive navigation documentation at `docs/navigation/app-shell-action-navigation.md`
  - Interactive demo screen showcasing all navigation patterns
  - Migration examples from service locator patterns to clean navigation

### Changed
- **AppShellAction Breaking Changes**:
  - `onPressed` parameter is now optional (was required)
  - Added assertion requiring one of: `onPressed`, `route`, or `onNavigate`
  - Cannot specify both `route` and `onNavigate` simultaneously
- **ActionButton Enhancement**: Complete rewrite to handle new navigation patterns with automatic error handling
- **Example App**: Updated to demonstrate all three navigation patterns with interactive examples

### Fixed
- **Navigation Context Problem**: Eliminated need for service locators in app bar actions
- **Toggle Actions**: Now support navigation alongside toggle functionality

### Migration Guide
```dart
// Before (Required Service Locator)
AppShellAction(
  icon: Icons.settings,
  tooltip: 'Settings',
  onPressed: () => GetIt.I<NavigationService>().go('/settings'),
)

// After (Clean & Direct)
AppShellAction.route(
  icon: Icons.settings,
  tooltip: 'Settings',
  route: '/settings',
)
```

## 0.5.0 - 2025-09-04

### Added
- **GitHub Release Integration**: Automated GitHub Release creation using `gh` CLI
- **New Commands**: 
  - `just github-release VERSION` - Creates a GitHub Release from an existing tag
  - `just publish-release VERSION` - Pushes and creates GitHub Release in one command  
  - `just create-missing-releases` - Creates GitHub Releases for all existing tags

### Changed
- **Release Workflow**: Enhanced to include GitHub Release creation instructions
- **Documentation**: Updated release process to clarify difference between git tags and GitHub Releases

### Fixed
- **Release Visibility**: Tags now properly appear as GitHub Releases on the repository page


## 0.4.0 - 2025-09-04

### Added
- **Release Management**: Comprehensive release workflow with semantic versioning commands (`release-patch`, `release-minor`, `release-major`)
- **Automated Changelog**: Auto-generation of CHANGELOG templates for new releases
- **Version Tagging**: Git tag creation and management for stable version references

### Changed
- **Justfile Improvements**: Enhanced with release automation, version tracking, and tag management commands

### Fixed
- **Shell Syntax**: Corrected bash variable expansion in justfile release commands for cross-platform compatibility


## 0.3.0 - 2024-12-10

### Bug Fixes
- **Fixed Cupertino SnackBar**: Replaced ScaffoldMessenger dependency with custom iOS-style overlay notification system
  - Implements authentic iOS notifications that slide from top with blur effect
  - Adds swipe-to-dismiss gesture support
  - Maintains API compatibility with ScaffoldFeatureController interface
  - No breaking changes for existing code

### New Features
- **Dedicated SnackBar Demo**: Added comprehensive demo screen showcasing platform-adaptive snackbar notifications
- **iOS-Style Notifications**: Custom overlay-based implementation for Cupertino mode providing authentic iOS experience

### Documentation
- Added comprehensive snackbar documentation at `docs/ui-systems/snackbars.md`
- Updated example app to demonstrate all snackbar features across UI systems

## 0.2.0 - 2024-08-28

### Enhanced Logging System
- **BREAKING CHANGE**: Migrated from `logger` package to `logging` package for better control
- **Hierarchical Logging**: Each service now has its own named logger with individual level control
- **Runtime Log Control**: Log levels can be adjusted through settings UI during app runtime  
- **Performance Optimization**: Automatic log level adjustment in release builds (warnings and above only)
- **Better Organization**: Service-specific loggers provide cleaner, more organized log output
- **Stream-Based Architecture**: Flexible log handling with custom stream listeners
- **Backward Compatibility**: Existing `AppShellLogger` API unchanged, no breaking changes for users

### New Features
- `createServiceLogger(String serviceName)` utility for hierarchical logging
- Per-service log level configuration capabilities
- Enhanced settings integration with reactive log level changes
- Lazy message evaluation for improved performance

### Developer Experience
- Better debugging with service-specific log filtering
- Visual log organization with service names and timestamps
- Reduced logging overhead in production builds

## 0.1.0 - 2024-08-06

### Initial Release
- Core AppShell framework with adaptive navigation
- Responsive layout system (mobile, tablet, desktop)
- Service architecture with GetIt dependency injection
- State management with Signals
- Dark/light theme support with Material 3
- Settings store with persistent preferences
- Navigation service with GoRouter integration
- Comprehensive logging system
- Example application demonstrating all features

### Features
- Adaptive navigation that switches between bottom tabs, rail, and sidebar
- Collapsible sidebar for desktop layouts
- Reactive state management with automatic UI updates
- Type-safe service locator pattern
- Theme customization support
- Zero-configuration setup with `runShellApp()`
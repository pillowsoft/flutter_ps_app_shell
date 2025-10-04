# Changelog

## 1.0.6 - 2025-10-03

### Added
- 

### Changed
- 

### Fixed
- 


## 1.0.5 - 2025-10-03

### Added
- 

### Changed
- 

### Fixed
- 


## 1.0.4 - 2025-10-03

### Added
- 

### Changed
- 

### Fixed
- 


## 1.0.3 - 2025-10-03

### Added
- 

### Changed
- 

### Fixed
- 


## 1.0.2 - 2025-10-03

### Added
- 

### Changed
- 

### Fixed
- 


## 1.0.1 - 2025-10-03

### Fixed

- **🐛 SignalEffectException when all routes have `showInNavigation: false`**: Fixed crash when using programmatic-only navigation
  - **Root Cause**: Bottom navigation bar, sidebar, and navigation rail were being created even when `visibleRoutes` was empty (all routes hidden)
  - **Symptom**: App crashed with `SignalEffectException` in `WatchBuilder` when trying to compute selected index with 0 navigation items
  - **Impact**: Apps using fully programmatic navigation (no persistent tabs/drawers) could not run
  - **Solution**: Added `visibleRoutes.isNotEmpty` safety check before creating navigation widgets
  - **Changes**:
    - `app_shell.dart:89` - Added `&& visibleRoutes.isNotEmpty` to bottom nav bar creation
    - `app_shell.dart:106` - Added `&& visibleRoutes.isNotEmpty` to sidebar creation
    - `app_shell.dart:116` - Added `&& visibleRoutes.isNotEmpty` to navigation rail creation
  - **Use Case**: Apps with task-driven UIs that use only programmatic navigation (buttons, actions) without persistent bottom tabs or sidebars
  - **Example**: All routes with `showInNavigation: false` now work correctly without crashes
  - Reported by developer: "App crashes when all routes have showInNavigation: false - useBottomNav=true with visibleRoutes=0"

## 1.0.0 - 2025-10-03

### Breaking Changes

- **🔄 BREAKING: Renamed `hideDrawer` to `hideNavigation`**: Parameter name now accurately reflects functionality
  - **Old Parameter**: `hideDrawer: bool` (misleading name - hides ALL navigation UI, not just drawers)
  - **New Parameter**: `hideNavigation: bool` (accurate name - describes actual behavior)
  - **What It Controls**: Hides ALL navigation UI elements across all platforms:
    - ✅ Bottom tab bar (iPhone/mobile ≤5 routes)
    - ✅ Mobile drawer (iPhone/mobile >5 routes)
    - ✅ Navigation rail (iPad/tablet 600-1200px)
    - ✅ Desktop sidebar (Desktop >1200px)
    - ✅ Drawer/menu buttons in app bar
  - **What It Preserves**:
    - ✅ GoRouter routing functionality (all programmatic navigation still works)
    - ✅ `context.go()`, `context.push()`, `context.pop()` methods
    - ✅ Back button functionality
    - ✅ App bar with title and actions
  - **Migration Guide**:
    ```dart
    // Before (v0.8.x)
    AppConfig(
      title: 'My App',
      routes: routes,
      hideDrawer: true,  // ❌ Old parameter name
    )

    // After (v0.9.0)
    AppConfig(
      title: 'My App',
      routes: routes,
      hideNavigation: true,  // ✅ New parameter name
    )
    ```
  - **Use Case**: Apps with fully programmatic navigation (no visible tabs/sidebars/drawers)
  - **Files Changed**:
    - `app_config.dart:8, 20` - Renamed parameter
    - `app_shell.dart:21, 31, 71, 89, 106, 116, 163, 218, 224, 230` - All references updated
    - `app_shell_runner.dart:382` - Parameter pass-through updated
  - **Breaking Change Reason**: The old name `hideDrawer` was misleading and caused confusion. The parameter hides ALL navigation UI (tabs, rails, sidebars, drawers), not just drawers. The new name accurately describes what it does.

## 0.8.0 - 2025-10-03

### Added
- **✨ Theme Toggle Control**: Added optional `showThemeToggle` parameter to `AppConfig` for controlling `DarkModeToggleButton` visibility
  - **New Parameter**: `showThemeToggle: bool` (default: `true`)
  - **Backwards Compatible**: Defaults to `true` to maintain existing behavior
  - **Use Case**: Apps with Settings-based theme switching can hide redundant header theme toggle
  - **Example**:
    ```dart
    AppConfig(
      title: 'My App',
      routes: routes,
      showThemeToggle: false,  // Hide header theme toggle
    )
    ```
  - **Changes**:
    - Added `showThemeToggle` to `AppConfig` (app_config.dart:15)
    - Added `showThemeToggle` to `AppShell` (app_shell.dart:24)
    - Updated app_shell.dart:158 to conditionally render `DarkModeToggleButton`
    - Updated app_shell_runner.dart:384 to pass `showThemeToggle` to `AppShell`
  - **Benefits**:
    - ✅ Full control over theme toggle placement
    - ✅ Reduces visual clutter for apps with settings-based theme switching
    - ✅ One-line configuration change
    - ✅ No breaking changes (defaults to existing behavior)
  - Requested by developer for Vizi app to eliminate redundant theme controls


## 0.7.31 - 2025-10-03

### Fixed
- **🐛 CupertinoPageScaffold Content Sliding Under Navigation Bar (v0.7.30 Regression)**: Fixed content sliding under navigation bar instead of appearing below it
  - **Root Cause**: v0.7.30 wrapped `CupertinoPageScaffold` in `Container` to extend background into safe areas, but this prevented scaffold's automatic content positioning logic from working
  - **Widget Hierarchy Problem (v0.7.30)**:
    ```
    Container (wrapper) ← Takes over layout control
      └─ CupertinoPageScaffold ← Can't add padding for nav bar
          └─ Content ← Slides under nav bar
    ```
  - **Solution**:
    - Moved `Container` **inside** `CupertinoPageScaffold` child instead of wrapping it
    - Added `SafeArea` with selective insets:
      - `top: false` - Navigation bar handles top spacing
      - `bottom: false` - Allow background extension to home indicator
      - `left/right: true` - Keep horizontal safe areas
    - Set scaffold `backgroundColor: Colors.transparent` (Container handles color)
  - **Widget Hierarchy (v0.7.31)**:
    ```
    CupertinoPageScaffold (controls layout) ✅
      └─ Container (background color) ✅
          └─ SafeArea (selective insets) ✅
              └─ Content (properly positioned)
    ```
  - **Changes**:
    - Modified `cupertino_widget_factory.dart` lines 141-161 (with bottom navigation)
    - Modified `cupertino_widget_factory.dart` lines 200-215 (without bottom navigation)
  - **Impact**:
    - ✅ Navigation bar content positioning fixed (content appears below nav bar)
    - ✅ Home indicator background extension preserved (v0.7.30 fix maintained)
    - ✅ Status bar styling preserved (v0.7.28/29 fixes maintained)
  - Reported by developer: "Container wrapper prevents CupertinoPageScaffold from positioning content below navigation bar"


## 0.7.30 - 2025-10-03

### Fixed
- **🐛 SafeArea Blocking iOS Home Indicator Background (v0.7.29 Critical Fix)**: Fixed v0.7.29 which still showed black bars because SafeArea wrapper prevented Container background extension
  - **Root Cause**: `app_shell.dart:138` wrapped ALL mobile scaffolds in SafeArea unconditionally, blocking Container (v0.7.29) from extending into safe area insets
  - **Widget Hierarchy Problem**:
    ```
    SafeArea (app_shell.dart) ← Blocks extension!
      └─ Container (background) ← Can't reach safe areas
          └─ CupertinoPageScaffold
    ```
  - **Solution**:
    - Conditionally apply SafeArea based on UI factory type
    - CupertinoWidgetFactory: No SafeArea wrapper (let Container extend into safe areas)
    - Material/ForUI: Keep SafeArea wrapper (they need it)
    - CupertinoPageScaffold handles safe areas for content internally
  - **Changes**:
    - Added `CupertinoWidgetFactory` import to `app_shell.dart`
    - Modified SafeArea logic to check UI factory type (lines 139-143)
    - iOS Cupertino: Returns unwrapped scaffold (Container extends to safe areas)
    - Material/ForUI: Returns SafeArea-wrapped scaffold (unchanged)
  - **Impact**:
    - iOS Cupertino: Container background finally extends into safe areas ✅
    - Android Cupertino: Navigation bar styling preserved (v0.7.28) ✅
    - Material/ForUI: SafeArea protection maintained ✅
  - Reported by developer: "SafeArea wrapper prevents Container background from extending into safe areas"


## 0.7.29 - 2025-10-03

### Fixed
- **🐛 iOS Home Indicator Black Bar (v0.7.28 Fix)**: Corrected v0.7.28 fix which didn't work on iOS
  - **Root Cause**: `systemNavigationBarColor` is "Only honored in Android versions O and greater" - completely ignored on iOS
  - **iOS Reality**: Home indicator color auto-adapts based on background color beneath it, cannot be directly styled
  - **Solution**:
    - Split `SystemUiOverlayStyle` into platform-specific configurations (iOS vs Android)
    - Removed iOS-incompatible `systemNavigationBarColor` properties for iOS
    - Wrapped `CupertinoPageScaffold` with `Container` to ensure background extends behind home indicator area
  - **Impact**:
    - iOS home indicator area now properly shows scaffold background color
    - Android navigation bar continues working correctly with v0.7.28 fix
    - Status bar styling works correctly on both platforms
  - Reported by developer: "v0.7.28 fix doesn't work for iOS because systemNavigationBarColor is Android-only"


## 0.7.28 - 2025-10-03

### Fixed
- **🐛 System UI Overlay Black Bars**: Fixed black bars appearing in status bar and home indicator areas across all three UI systems
  - **Root Cause**: Scaffold implementations didn't configure system UI overlay styling, causing iOS/Android system regions to display black instead of matching scaffold background
  - **Solution**: Wrapped all scaffold returns with `AnnotatedRegion<SystemUiOverlayStyle>` to match system UI colors to scaffold backgrounds
  - **Affected Files**: `cupertino_widget_factory.dart`, `material_widget_factory.dart`, `forui_widget_factory.dart`
  - **Impact**: Status bar and navigation bar areas now properly match scaffold background colors with correct icon brightness across Cupertino, Material, and ForUI
  - Reported in bug analysis showing black system UI regions on light-colored scaffolds


## 0.7.27 - 2025-10-02

### Fixed
- **🐛 Cupertino Button Padding Consistency**: Fixed padding inconsistency between filled and outlined buttons
  - Added missing `padding: EdgeInsets.zero` to `outlinedButton()`
  - Previously, `outlinedButton()` used CupertinoButton's default 16px padding + Container's 16px padding = 32px total
  - Now all button types consistently use zero button padding + Container's 16px padding = 16px total
  - Ensures uniform visual width across all button types (filled, outlined, with/without icons)

## 0.7.26 - 2025-10-02

### Fixed
- **🐛 Cupertino Button Width Constraints (Correct Fix)**: Fixed v0.7.25 implementation that used wrong pattern
  - **Root Cause**: v0.7.25 wrapped CupertinoButton in SizedBox, but CupertinoButton doesn't respect parent width constraints
  - **Correct Solution**: Container with `width: double.infinity` must be the button's **child**, not its wrapper
  - Applied correct pattern from `outlinedButton()` to `button()` and `buttonWithIcon()`
  - Set `padding: EdgeInsets.zero` on CupertinoButton.filled
  - Added Container(width: double.infinity) as button's child with proper padding
  - Now matches the pattern used by outlined buttons for consistency
  - CupertinoButton.filled now properly expands to fill available width
  - ⚠️ Note: Still had padding inconsistency in `outlinedButton()` - fixed in v0.7.27

## 0.7.25 - 2025-10-02 [DEPRECATED - INCORRECT FIX]

### Fixed
- **🐛 Filled Button Width Constraints**: ⚠️ This release used incorrect approach (SizedBox wrapper)
  - Used wrong pattern: wrapped button in SizedBox instead of Container as child
  - CupertinoButton doesn't expand with SizedBox wrapper - fix didn't work
  - See v0.7.26 for correct implementation

## 0.7.24 - 2025-10-02

### Fixed
- **🐛 Outlined Button Width Constraints**: Fixed outlined buttons not respecting parent width constraints
  - `outlinedButton()` and `outlinedButtonWithIcon()` in CupertinoWidgetFactory now expand to fill available width
  - Added `width: double.infinity` to Container wrappers
  - Added proper text/icon centering (Center widget and MainAxisAlignment.center)
  - Fixed same issue in ForUIWidgetFactory for consistency across all UI systems
  - Buttons wrapped in `SizedBox(width: double.infinity)` now display with uniform width
  - Resolves visual inconsistency when mixing filled and outlined buttons in layouts

## 0.7.14 - 2025-09-07

### Fixed
- **🐛 DatabaseService Race Condition**: Fixed critical race condition in query methods
  - `findAll()`, `findWhere()`, and `read()` were returning empty results on initial query
  - Methods were synchronously reading signal values before WebSocket responses arrived
  - Now uses InstantDB's `queryOnce()` API which properly waits for initial data load
  - This ensures reliable data retrieval on first call instead of empty results
  - Root cause: Synchronous read of reactive signal before async data population

## 0.7.13 - 2025-09-06

### Fixed
- **🐛 ForUI Dialog Compilation**: Fixed compilation errors in ForUIWidgetFactory dialog implementations
  - Replaced ForUI component references with Material equivalents
  - Used LinearProgressIndicator instead of FProgress
  - Applied custom styling to maintain ForUI design aesthetics
  - Ensures compatibility when ForUI package is not available

## 0.7.12 - 2025-09-06

### Added
- **🎯 Enhanced Dialog System**: Comprehensive dialog handling improvements based on developer feedback
  - `DialogHandle` class for managing dialog lifecycle with state updates
  - `LoadingDialogController` for loading dialogs with message updates
  - `ProgressDialogController` for progress tracking with step management
  - Safe dialog dismissal methods: `dismissDialog()`, `hasDialog()`, `dismissDialogIfShowing()`
  - Built-in loading dialog: `showLoadingDialog()` with updatable messages
  - Progress dialog support: `showProgressDialog()` with step tracking
  - Platform-adaptive implementations across Material, Cupertino, and ForUI

### Enhanced
- **🚀 NavigationService Dialog Awareness**: Navigation service now coordinates with dialog system
  - Dialog state tracking to prevent navigation conflicts
  - `safeNavigate()` method that handles dialog dismissal
  - Before-navigate callbacks for dialog auto-dismissal
  - Context stack management for modal awareness
  - Prevention of "black screen" issue from incorrect Navigator.pop() calls
  - `canNavigate()` check for dialog-aware navigation guards

### Developer Experience
- **📝 Simplified Dialog Patterns**: No more manual Navigator context confusion
  - Automatic handling of `rootNavigator: true` context
  - Dialog handles for easy dismissal without context issues
  - Reactive state updates for loading and progress messages
  - Integration with GoRouter navigation prevents conflicts

## 0.7.11 - 2025-09-05

### Fixed
- **🚨 CRITICAL: InstantDB Transaction API Usage**: Fixed DatabaseService methods using incorrect InstantDB transaction builder API
  - `create()` now uses `tx[collection].create(data)` instead of `tx[collection][id].update(data)`
  - `delete()` now uses `tx[collection][id].delete()` instead of `_db!.delete(id)`
  - This generates proper `OperationType.add` and `OperationType.delete` operations
  - **Root Cause**: Using wrong operation types caused InstantDB sync engine to skip all attributes, sending transactions with "0 steps"
  - **Impact**: Fixes complete failure of data synchronization to InstantDB server - all CRUD operations now work correctly
  - Transactions now send proper step counts and data persists to cloud successfully

## 0.7.10 - 2025-09-05

### Fixed
- **🐛 InstantDB Query Syntax Error**: Fixed critical bug in DatabaseService.read() method
  - Corrected InstantDB query syntax by wrapping field conditions in 'where' clause
  - Query now properly uses `{'$': {'where': {'id': id}}}` instead of `{'$': {'id': id}}`
  - This fix resolves document retrieval failures that also affected update() and delete() operations
  - All CRUD operations now function correctly with InstantDB backend

## 0.7.9 - 2025-09-05

### Fixed
- **🐛 Navigation Rail Vertical Alignment**: Fixed navigation rail items being vertically centered in Material and Cupertino modes
  - Material: Wrapped NavigationRail's SingleChildScrollView in Align widget with topCenter alignment
  - Cupertino: Added Align wrapper with topCenter alignment and mainAxisAlignment.start to Column
  - Navigation items now consistently appear at the top in collapsed sidebar mode across all UI systems
  - Completes the vertical alignment fixes started in v0.7.8 for drawer/sidebar navigation

## 0.7.8 - 2025-09-05

### Fixed
- **🐛 Collapsed Sidebar Icons Vertical Alignment**: Fixed collapsed sidebar navigation icons being centered vertically instead of top-aligned
  - Wrapped collapsed Column in Align widget with topCenter alignment
  - Added mainAxisSize.min to ensure Column only takes needed space
  - Icons now consistently appear at the top in both collapsed and expanded states
  - Maintains horizontal center alignment while fixing vertical positioning

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
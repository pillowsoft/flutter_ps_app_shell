# Changelog

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
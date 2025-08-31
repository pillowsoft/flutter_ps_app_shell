# Flutter App Shell Example

This example demonstrates the capabilities of the Flutter App Shell framework.

## Features Demonstrated

- 🎨 **Adaptive Navigation**: Automatically switches between bottom tabs, navigation rail, and sidebar based on screen size
- 🌓 **Dark Mode**: Toggle between light and dark themes with a single click
- ⚙️ **Settings Management**: Comprehensive settings page with reactive state management using Signals
- 📊 **Dashboard**: Responsive grid layout that adapts to different screen sizes
- 👤 **Profile**: Example of a profile page with statistics and activity feed
- 🏠 **Home**: Landing page with navigation examples

## Running the Example

```bash
# From the project root
just run

# Or directly
cd example
flutter run
```

## Available Commands

```bash
# Run on specific platforms
just run-web      # Run on Chrome
just run-ios      # Run on iOS Simulator
just run-android  # Run on Android
just run-macos    # Run on macOS

# Build for production
just build-web
just build-ios
just build-android
just build-macos

# Run tests
just test-example
```

## Key Concepts

### Service Architecture
The app uses GetIt for dependency injection, providing clean separation of concerns and testability.

### State Management
Uses Signals for reactive state management, providing automatic UI updates when state changes.

### Responsive Design
The app automatically adapts its layout based on screen size:
- Mobile (<600px): Bottom navigation
- Tablet (600-1200px): Navigation rail
- Desktop (>1200px): Collapsible sidebar

## Customization

You can customize the app by modifying the `AppConfig` in `main.dart`:

```dart
AppConfig(
  title: 'Your App Name',
  routes: [...],  // Your app routes
  actions: [...], // App bar actions
  themeExtensions: (theme) => theme, // Custom theme
)
```
# Installation Guide

Get started with Flutter App Shell Framework in minutes.

## Requirements

- **Flutter SDK**: >=3.16.0
- **Dart SDK**: ^3.6.0
- **Platforms**: Android, iOS, Web, Windows, macOS, Linux

## Quick Install

### 1. Add Dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_app_shell:
    git:
      url: https://github.com/yourusername/flutter_app_shell.git
      ref: main  # or specific version tag
```

### 2. Install Packages

```bash
flutter pub get
```

### 3. Create Your First App

```dart
import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run app with zero configuration
  await runShellApp(
    appConfig: AppConfig(
      title: 'My App',
      routes: [
        AppRoute(
          title: 'Home',
          path: '/',
          icon: Icons.home,
          builder: (context, state) => const HomeScreen(),
        ),
        AppRoute(
          title: 'Settings',
          path: '/settings',
          icon: Icons.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  );
}
```

### 4. Run Your App

```bash
flutter run
```

That's it! You now have a fully functional app with:
- ✅ Responsive navigation (bottom tabs → rail → sidebar)
- ✅ Adaptive UI (Material/Cupertino/ForUI switching)
- ✅ Dark mode toggle
- ✅ Settings persistence
- ✅ Service architecture

## Optional: Cloud Features

For authentication and real-time sync, configure InstantDB:

### 1. Get InstantDB App ID

Sign up at https://www.instantdb.com and create an app.

### 2. Create `.env` File

```bash
# Copy template
cp .env.example .env

# Edit .env
INSTANTDB_APP_ID=your-app-id-here
INSTANTDB_ENABLE_SYNC=true
```

### 3. Add to pubspec.yaml

```yaml
flutter:
  assets:
    - .env
```

### 4. Use Authentication

```dart
final auth = getIt<AuthenticationService>();

// Magic link sign-in (recommended)
await auth.signInWithMagicLink('user@example.com');

// Or password-based
await auth.signUp('user@example.com', 'password', 'Full Name');
```

## Project Structure

Recommended structure for apps using this framework:

```
my_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── features/              # Feature modules
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   └── settings/
│   │       └── settings_screen.dart
│   ├── models/                # Data models
│   ├── services/              # Custom services
│   └── widgets/               # Shared widgets
├── assets/                    # Images, fonts
├── .env                       # Environment config (gitignored)
├── .env.example               # Environment template
└── pubspec.yaml
```

## Platform-Specific Setup

### Android

No additional setup required.

### iOS

No additional setup required.

### Web

No additional setup required.

### macOS

Add to `macos/Runner/DebugProfile.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

### Windows

No additional setup required.

### Linux

No additional setup required.

## Next Steps

- 📖 [Quick Start Examples](quickstart-examples.md)
- 🎨 [UI Systems](ui-systems/README.md)
- 🔧 [Services](services/README.md)
- ☁️ [Cloud Integration](cloud/README.md)

## Troubleshooting

### "Package not found"

Ensure you have access to the repository and your SSH keys are configured:

```bash
ssh -T git@github.com
```

### "Minimum SDK version"

Update your Flutter SDK:

```bash
flutter upgrade
flutter doctor
```

### "InstantDB not connecting"

1. Check `.env` file exists and has valid `INSTANTDB_APP_ID`
2. Verify `.env` is in `pubspec.yaml` assets
3. Run `flutter clean && flutter pub get`
4. Check InstantDB dashboard for app status

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/flutter_app_shell/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/flutter_app_shell/discussions)
- **Examples**: See `example/` directory

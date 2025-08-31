import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import '../../state/app_shell_settings_store.dart';

/// Enum representing different adaptive platforms
enum AdaptivePlatform {
  material,
  cupertino,
  forui,
}

/// Provides adaptive text styles and color schemes based on the current UI system
class AdaptiveStyleProvider {
  final BuildContext context;
  final String? _overrideUiSystem;

  AdaptiveStyleProvider(this.context, {String? overrideUiSystem})
      : _overrideUiSystem = overrideUiSystem;

  /// Static method to get AdaptiveStyleProvider from context
  static AdaptiveStyleProvider of(BuildContext context) {
    return AdaptiveStyleProvider(context);
  }

  String get uiSystem {
    if (_overrideUiSystem != null) return _overrideUiSystem!;
    final settingsStore = GetIt.I<AppShellSettingsStore>();
    return settingsStore.uiSystem.value;
  }

  /// Get the current platform as AdaptivePlatform enum
  AdaptivePlatform get platform {
    switch (uiSystem) {
      case 'cupertino':
        return AdaptivePlatform.cupertino;
      case 'forui':
        return AdaptivePlatform.forui;
      default:
        return AdaptivePlatform.material;
    }
  }

  /// Get headline large text style
  TextStyle get headlineLarge {
    switch (uiSystem) {
      case 'forui':
        return const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFF020817), // zinc-950
          height: 1.2,
        );
      case 'cupertino':
        return const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.label,
        );
      default: // material
        return Theme.of(context).textTheme.headlineLarge ?? const TextStyle();
    }
  }

  /// Get headline medium text style
  TextStyle get headlineMedium {
    switch (uiSystem) {
      case 'forui':
        return const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFF020817), // zinc-950
          height: 1.3,
        );
      case 'cupertino':
        return const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label,
        );
      default: // material
        return Theme.of(context).textTheme.headlineMedium ?? const TextStyle();
    }
  }

  /// Get headline small text style
  TextStyle get headlineSmall {
    switch (uiSystem) {
      case 'forui':
        return const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF020817), // zinc-950
          height: 1.3,
        );
      case 'cupertino':
        return const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label,
        );
      default: // material
        return Theme.of(context).textTheme.headlineSmall ?? const TextStyle();
    }
  }

  /// Get title large text style
  TextStyle get titleLarge {
    switch (uiSystem) {
      case 'forui':
        return const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF020817), // zinc-950
          height: 1.4,
        );
      case 'cupertino':
        return const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label,
        );
      default: // material
        return Theme.of(context).textTheme.titleLarge ?? const TextStyle();
    }
  }

  /// Get title medium text style
  TextStyle get titleMedium {
    switch (uiSystem) {
      case 'forui':
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF020817), // zinc-950
          height: 1.4,
        );
      case 'cupertino':
        return const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label,
        );
      default: // material
        return Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    }
  }

  /// Get body large text style
  TextStyle get bodyLarge {
    switch (uiSystem) {
      case 'forui':
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF71717A), // zinc-500
          height: 1.5,
        );
      case 'cupertino':
        return const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: CupertinoColors.secondaryLabel,
        );
      default: // material
        return Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    }
  }

  /// Get body medium text style
  TextStyle get bodyMedium {
    switch (uiSystem) {
      case 'forui':
        return const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF71717A), // zinc-500
          height: 1.5,
        );
      case 'cupertino':
        return const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: CupertinoColors.label,
        );
      default: // material
        return Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    }
  }

  /// Get body small text style
  TextStyle get bodySmall {
    switch (uiSystem) {
      case 'forui':
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF71717A), // zinc-500
          height: 1.4,
        );
      case 'cupertino':
        return const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: CupertinoColors.secondaryLabel,
        );
      default: // material
        return Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    }
  }

  /// Get label small text style
  TextStyle get labelSmall {
    switch (uiSystem) {
      case 'forui':
        return const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF71717A), // zinc-500
          height: 1.4,
        );
      case 'cupertino':
        return const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: CupertinoColors.secondaryLabel,
        );
      default: // material
        return Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    }
  }

  /// Get primary color
  Color get primary {
    switch (uiSystem) {
      case 'forui':
        return const Color(0xFF020817); // zinc-950
      case 'cupertino':
        return CupertinoColors.activeBlue;
      default: // material
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Get primary container color
  Color get primaryContainer {
    switch (uiSystem) {
      case 'forui':
        return const Color(0xFFF4F4F5); // zinc-100
      case 'cupertino':
        return CupertinoColors.systemGrey6;
      default: // material
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  /// Get on primary container color
  Color get onPrimaryContainer {
    switch (uiSystem) {
      case 'forui':
        return const Color(0xFF020817); // zinc-950
      case 'cupertino':
        return CupertinoColors.label;
      default: // material
        return Theme.of(context).colorScheme.onPrimaryContainer;
    }
  }

  /// Get surface variant color
  Color get onSurfaceVariant {
    switch (uiSystem) {
      case 'forui':
        return const Color(0xFF71717A); // zinc-500
      case 'cupertino':
        return CupertinoColors.secondaryLabel;
      default: // material
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  /// Get error color
  Color get error {
    switch (uiSystem) {
      case 'forui':
        return const Color(0xFFEF4444); // red-500
      case 'cupertino':
        return CupertinoColors.destructiveRed;
      default: // material
        return Theme.of(context).colorScheme.error;
    }
  }

  /// Get divider color
  Color get divider {
    switch (uiSystem) {
      case 'forui':
        return const Color(0xFFE4E4E7); // zinc-200
      case 'cupertino':
        return CupertinoColors.separator;
      default: // material
        return Theme.of(context).dividerColor;
    }
  }

  /// Get card background color
  Color get cardBackground {
    switch (uiSystem) {
      case 'forui':
        return Colors.white;
      case 'cupertino':
        return CupertinoColors.systemBackground;
      default: // material
        return Theme.of(context).cardColor;
    }
  }

  /// Get surface color
  Color get surface {
    switch (uiSystem) {
      case 'forui':
        return Colors.white;
      case 'cupertino':
        return CupertinoColors.systemBackground;
      default: // material
        return Theme.of(context).colorScheme.surface;
    }
  }

  /// Get surface variant color
  Color get surfaceVariant {
    switch (uiSystem) {
      case 'forui':
        return const Color(0xFFF4F4F5); // zinc-100
      case 'cupertino':
        return CupertinoColors.systemGrey6;
      default: // material
        return Theme.of(context).colorScheme.surfaceVariant;
    }
  }

  /// Get on primary color
  Color get onPrimary {
    switch (uiSystem) {
      case 'forui':
        return Colors.white;
      case 'cupertino':
        return Colors.white;
      default: // material
        return Theme.of(context).colorScheme.onPrimary;
    }
  }

  /// Get outline variant color
  Color get outlineVariant {
    switch (uiSystem) {
      case 'forui':
        return const Color(0xFFE4E4E7); // zinc-200
      case 'cupertino':
        return CupertinoColors.separator;
      default: // material
        return Theme.of(context).colorScheme.outlineVariant;
    }
  }
}

/// Extension to easily access adaptive styles from BuildContext
extension AdaptiveStyleExtension on BuildContext {
  AdaptiveStyleProvider get adaptiveStyle => AdaptiveStyleProvider(this);
}

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const String _themeKey = 'theme_mode';
  static const String _customColorsKey = 'custom_colors';

  // Theme mode signal
  final themeModeSignal = signal<ThemeMode>(ThemeMode.system);

  // Custom colors signal
  final customColorsSignal = signal<Map<String, Color>>({});

  // Singleton instance
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  /// Initialize theme manager with saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    themeModeSignal.value = ThemeMode.values[themeIndex];

    // Load custom colors
    final customColorsJson = prefs.getStringList(_customColorsKey) ?? [];
    final customColors = <String, Color>{};
    for (final colorString in customColorsJson) {
      final parts = colorString.split(':');
      if (parts.length == 2) {
        final key = parts[0];
        final colorValue = int.tryParse(parts[1]);
        if (colorValue != null) {
          customColors[key] = Color(colorValue);
        }
      }
    }
    customColorsSignal.value = customColors;
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeSignal.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  /// Set custom color
  Future<void> setCustomColor(String key, Color color) async {
    final current = Map<String, Color>.from(customColorsSignal.value);
    current[key] = color;
    customColorsSignal.value = current;

    final prefs = await SharedPreferences.getInstance();
    final colorStrings = current.entries
        .map((entry) => '${entry.key}:0x${entry.value.value.toRadixString(16)}')
        .toList();
    await prefs.setStringList(_customColorsKey, colorStrings);
  }

  /// Remove custom color
  Future<void> removeCustomColor(String key) async {
    final current = Map<String, Color>.from(customColorsSignal.value);
    current.remove(key);
    customColorsSignal.value = current;

    final prefs = await SharedPreferences.getInstance();
    final colorStrings = current.entries
        .map((entry) => '${entry.key}:0x${entry.value.value.toRadixString(16)}')
        .toList();
    await prefs.setStringList(_customColorsKey, colorStrings);
  }

  /// Get custom color or fallback to default
  Color getCustomColor(String key, Color defaultColor) {
    return customColorsSignal.value[key] ?? defaultColor;
  }

  /// Reset all custom colors
  Future<void> resetCustomColors() async {
    customColorsSignal.value = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customColorsKey);
  }

  /// Get theme mode display name
  String getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get all available theme modes
  List<ThemeMode> get availableThemeModes => ThemeMode.values;

  /// Check if system is in dark mode
  bool isSystemDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  /// Get effective theme mode based on system settings
  ThemeMode getEffectiveThemeMode(BuildContext context) {
    if (themeModeSignal.value == ThemeMode.system) {
      return isSystemDarkMode(context) ? ThemeMode.dark : ThemeMode.light;
    }
    return themeModeSignal.value;
  }

  /// Check if current theme is dark
  bool isDarkMode(BuildContext context) {
    final effectiveMode = getEffectiveThemeMode(context);
    return effectiveMode == ThemeMode.dark;
  }

  /// Get adaptive color based on theme
  Color getAdaptiveColor(
      BuildContext context, Color lightColor, Color darkColor) {
    return isDarkMode(context) ? darkColor : lightColor;
  }

  /// Get theme-aware text color
  Color getTextColor(BuildContext context, {bool isSecondary = false}) {
    final theme = Theme.of(context);
    if (isSecondary) {
      return theme.colorScheme.onSurfaceVariant;
    }
    return theme.colorScheme.onSurface;
  }

  /// Get theme-aware background color
  Color getBackgroundColor(BuildContext context, {bool isCard = false}) {
    final theme = Theme.of(context);
    if (isCard) {
      return theme.colorScheme.surface;
    }
    return theme.colorScheme.surface;
  }

  /// Get theme-aware icon color
  Color getIconColor(BuildContext context, {bool isSecondary = false}) {
    final theme = Theme.of(context);
    if (isSecondary) {
      return theme.colorScheme.onSurfaceVariant;
    }
    return theme.colorScheme.onSurface;
  }

  /// Get theme-aware border color
  Color getBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme.outline;
  }

  /// Get theme-aware overlay color
  Color getOverlayColor(BuildContext context, {double opacity = 0.1}) {
    final theme = Theme.of(context);
    return theme.colorScheme.onSurface.withValues(alpha: opacity);
  }
}

/// Widget that rebuilds when theme changes
class ThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ThemeMode themeMode) builder;

  const ThemeBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final themeMode = ThemeManager().themeModeSignal.value;
      return builder(context, themeMode);
    });
  }
}

/// Widget that provides theme-aware colors
class ThemedContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;

  const ThemedContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.margin,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = ThemeManager();

    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ??
            themeManager.getBackgroundColor(context, isCard: true),
        border: borderColor != null || borderWidth != null
            ? Border.all(
                color: borderColor ?? themeManager.getBorderColor(context),
                width: borderWidth ?? 1.0,
              )
            : null,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: themeManager.getOverlayColor(context, opacity: 0.1),
                  blurRadius: elevation!,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Extension to easily access theme manager
extension ThemeManagerExtension on BuildContext {
  ThemeManager get themeManager => ThemeManager();

  bool get isDarkMode => themeManager.isDarkMode(this);

  Color adaptiveColor(Color lightColor, Color darkColor) {
    return themeManager.getAdaptiveColor(this, lightColor, darkColor);
  }

  Color get adaptiveTextColor => themeManager.getTextColor(this);
  Color get adaptiveSecondaryTextColor =>
      themeManager.getTextColor(this, isSecondary: true);
  Color get adaptiveBackgroundColor => themeManager.getBackgroundColor(this);
  Color get adaptiveCardColor =>
      themeManager.getBackgroundColor(this, isCard: true);
  Color get adaptiveIconColor => themeManager.getIconColor(this);
  Color get adaptiveBorderColor => themeManager.getBorderColor(this);
}

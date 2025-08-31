import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../services/settings_service.dart';
import 'adaptive_widget_factory.dart';
import 'material_widget_factory.dart';
import 'cupertino_widget_factory.dart';
// import 'forui_widget_factory.dart'; // Temporarily disabled due to compatibility issues

export 'adaptive_widget_factory.dart';

/// Sets up the adaptive UI factory in the service locator
void setupAdaptiveUI() {
  // Register all factory implementations
  getIt.registerLazySingleton<MaterialWidgetFactory>(
      () => MaterialWidgetFactory());
  getIt.registerLazySingleton<CupertinoWidgetFactory>(
      () => CupertinoWidgetFactory());
  // getIt.registerLazySingleton<ForuiWidgetFactory>(() => ForuiWidgetFactory()); // Temporarily disabled
}

/// Gets the appropriate adaptive widget factory based on current settings
AdaptiveWidgetFactory getAdaptiveFactory(BuildContext context) {
  final settingsService = getIt<SettingsService>();
  final style = settingsService.platformStyle.value;

  switch (style) {
    case 'material':
      return getIt<MaterialWidgetFactory>();
    case 'cupertino':
      return getIt<CupertinoWidgetFactory>();
    case 'forui':
      // Temporarily fallback to Material when Forui is selected
      return getIt<MaterialWidgetFactory>();
    // return getIt<ForuiWidgetFactory>(); // Temporarily disabled
    case 'adaptive':
    default:
      // Platform-based selection for adaptive mode
      if (Platform.isIOS || Platform.isMacOS) {
        return getIt<CupertinoWidgetFactory>();
      }
      return getIt<MaterialWidgetFactory>();
  }
}

/// Helper widget that provides the adaptive factory to its children
class AdaptiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AdaptiveWidgetFactory ui) builder;

  const AdaptiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    return builder(context, ui);
  }
}

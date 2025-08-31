import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../state/app_shell_settings_store.dart';
import 'adaptive_widget_factory.dart';
import 'material_widget_factory.dart';
import 'cupertino_widget_factory.dart';
import 'forui_widget_factory.dart';

export 'adaptive_style_provider.dart';
export 'components/adaptive_components.dart';

/// Get the appropriate adaptive widget factory based on current UI system setting
AdaptiveWidgetFactory getAdaptiveFactory(BuildContext context) {
  final settingsStore = GetIt.I<AppShellSettingsStore>();
  final uiSystem = settingsStore.uiSystem.value;

  switch (uiSystem) {
    case 'material':
      return MaterialWidgetFactory();
    case 'cupertino':
      return CupertinoWidgetFactory();
    case 'forui':
      return ForUIWidgetFactory();
    default:
      return MaterialWidgetFactory();
  }
}

/// Get the adaptive widget factory for a specific UI system
AdaptiveWidgetFactory getAdaptiveFactoryForSystem(String uiSystem) {
  switch (uiSystem) {
    case 'material':
      return MaterialWidgetFactory();
    case 'cupertino':
      return CupertinoWidgetFactory();
    case 'forui':
      return ForUIWidgetFactory();
    default:
      return MaterialWidgetFactory();
  }
}

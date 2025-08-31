// Flutter App Shell - A comprehensive application framework for rapid Flutter development

// Core exports
export 'src/core/app_shell.dart';
export 'src/core/app_shell_runner.dart';
export 'src/core/app_config.dart';
export 'src/core/app_route.dart';
export 'src/core/app_shell_action.dart';

// Service exports
export 'src/services/service_locator.dart';
export 'src/services/navigation_service.dart';
export 'src/services/database_service.dart';
export 'src/services/preferences_service.dart';
export 'src/services/network_service.dart';
export 'src/services/authentication_service.dart';
export 'src/services/file_storage_service.dart';
export 'src/services/logging_service.dart';
export 'src/services/cloudflare_service.dart';
export 'src/services/window_state_service.dart';

// State management exports
export 'src/state/app_shell_settings_store.dart';

// Model exports
export 'src/models/document.dart';

// Utility exports
export 'src/utils/logger.dart';

// UI component exports
export 'src/ui/components/action_button.dart';
export 'src/ui/components/dark_mode_toggle_button.dart';

// Navigation exports
export 'src/navigation/drawer_content.dart';

// Adaptive UI exports
export 'src/ui/adaptive/adaptive_widget_factory.dart';
export 'src/ui/adaptive/adaptive_widgets.dart';
export 'src/ui/adaptive/adaptive_style_provider.dart';
export 'src/ui/adaptive/material_widget_factory.dart';
export 'src/ui/adaptive/cupertino_widget_factory.dart';
export 'src/ui/adaptive/forui_widget_factory.dart';

// Wizard system exports
export 'src/wizard/wizard.dart';

// Plugin system exports
export 'src/plugins/plugins.dart';

// Re-export commonly used packages
export 'package:go_router/go_router.dart';
export 'package:get_it/get_it.dart';
export 'package:signals/signals_flutter.dart';

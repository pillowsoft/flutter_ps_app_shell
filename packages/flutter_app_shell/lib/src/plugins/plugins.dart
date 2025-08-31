/// Flutter App Shell Plugin System
///
/// This module provides a comprehensive plugin system for extending App Shell
/// capabilities with service plugins, widget extensions, theme plugins, and
/// workflow automation.

// Core plugin infrastructure
export 'core/plugin_manager.dart';
export 'core/plugin_registry.dart';
export 'core/plugin_discovery.dart';

// Plugin interfaces
export 'interfaces/base_plugin.dart';
export 'interfaces/service_plugin.dart';
export 'interfaces/widget_plugin.dart';
export 'interfaces/theme_plugin.dart';
export 'interfaces/workflow_plugin.dart';

// Example plugins (for demonstration and testing)
export 'examples/example_plugins.dart';

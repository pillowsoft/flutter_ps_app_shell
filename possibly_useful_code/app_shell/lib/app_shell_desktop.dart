import 'dart:ui';
import 'package:app_shell/src/signal_stores/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';
import 'package:app_shell/src/utilities/logger.dart';

Future<void> initializeDesktopApp() async {
  // Initialize window_manager
  await windowManager.ensureInitialized();
  logger.i('After: windowManager.ensureInitialized()');

  // Load saved window bounds
  logger.i('Loading window bounds');
  final persistedBounds = await _loadWindowBounds();

  // Set window options
  WindowOptions windowOptions = WindowOptions(
    size: persistedBounds?.size ?? const Size(800, 600),
    minimumSize: const Size(400, 600),
    center: persistedBounds == null,
  );

  logger.i('Setting window options: $windowOptions');
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Add window listener
  windowManager.addListener(AppWindowListener());
}

class AppWindowListener extends WindowListener {
  // @override
  // void onWindowClose() async {
  //   logger.i('Window close event received');
  //   await _saveWindowBounds();
  //   await windowManager.destroy();
  // }

  @override
  Future<void> onWindowResized() async {
    logger.i('Window resized event received');
    super.onWindowResized();
    if (!kIsWeb) {
      _saveWindowBounds();
    }
  }

  @override
  Future<void> onWindowMoved() async {
    logger.i('Window move event received');
    super.onWindowMoved();
    if (!kIsWeb) {
      _saveWindowBounds();
    }
  }
}

Future<Rect?> _loadWindowBounds() async {
  final settingsStore = GetIt.instance.get<AppShellSettingsStore>();
  final windowPlacement = settingsStore.windowPlacement.value;
  logger.i('Loading window bounds: $windowPlacement');

  if (windowPlacement != const Rect.fromLTWH(0, 0, 800, 600)) {
    logger.i('Returning persisted window bounds: $windowPlacement');
    return windowPlacement;
  }
  logger.i('No persisted bounds found, returning null');
  return null;
}

Future<void> _saveWindowBounds() async {
  final bounds = await windowManager.getBounds();
  logger.i('Saving window bounds: $bounds');

  final settingsStore = GetIt.instance.get<AppShellSettingsStore>();
  settingsStore.saveWindowBounds(bounds);
}

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:signals/signals.dart';
import 'preferences_service.dart';
import '../utils/logger.dart';
import 'package:logging/logging.dart';

/// Service for managing window state persistence on desktop platforms
/// Automatically saves and restores window position, size, and state
class WindowStateService with WindowListener {
  // Service-specific logger
  static final Logger _logger = createServiceLogger('WindowStateService');

  static WindowStateService? _instance;
  static WindowStateService get instance =>
      _instance ??= WindowStateService._();

  WindowStateService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isRestoring = false;
  Timer? _saveDebounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  // Reactive signals for window state
  final windowPosition = signal<Offset?>(null);
  final windowSize = signal<Size?>(null);
  final isMaximized = signal<bool>(false);
  final isFullScreen = signal<bool>(false);
  final isMinimized = signal<bool>(false);

  // Settings signals
  final rememberWindowState = signal<bool>(true);
  final startMaximized = signal<bool>(false);

  // Storage keys for preferences
  static const _keyPositionX = 'window.position.x';
  static const _keyPositionY = 'window.position.y';
  static const _keySizeWidth = 'window.size.width';
  static const _keySizeHeight = 'window.size.height';
  static const _keyMaximized = 'window.state.maximized';
  static const _keyFullScreen = 'window.state.fullscreen';
  static const _keyDisplayId = 'window.display.id';
  static const _keyRememberState = 'window.settings.remember';
  static const _keyStartMaximized = 'window.settings.start_maximized';

  /// Initialize the window state service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Only initialize on desktop platforms
    if (kIsWeb ||
        !(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      _logger.info(
          'WindowStateService: Skipping initialization on non-desktop platform');
      return;
    }

    try {
      _logger.info('Initializing window state service...');

      // Load user preferences
      await _loadPreferences();

      // Add window listener for state changes - do this early!
      windowManager.addListener(this);
      _logger.info('WindowListener registered successfully');

      // Initialize current window state
      await _updateCurrentState();

      // Log the initial state
      _logger.info(
          'Initial window state - Position: ${windowPosition.value}, Size: ${windowSize.value}');

      _isInitialized = true;
      _logger.info('Window state service initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to initialize window state service', e, stackTrace);
      rethrow;
    }
  }

  /// Dispose of the service and remove listeners
  void dispose() {
    if (!_isInitialized) return;

    windowManager.removeListener(this);
    _saveDebounceTimer?.cancel();
    _isInitialized = false;

    _logger.info('Window state service disposed');
  }

  /// Load window state from storage and apply it
  Future<void> restoreWindowState() async {
    if (!_isInitialized || !rememberWindowState.value) {
      _logger.info('Window state restoration skipped');
      return;
    }

    _isRestoring = true;
    try {
      final prefs = PreferencesService.instance;

      // Get saved state
      final wasMax =
          prefs.getBool(_keyMaximized, defaultValue: false).value ?? false;
      final wasFull =
          prefs.getBool(_keyFullScreen, defaultValue: false).value ?? false;

      // Get saved geometry
      final savedX = prefs.getDouble(_keyPositionX).value;
      final savedY = prefs.getDouble(_keyPositionY).value;
      final savedW = prefs.getDouble(_keySizeWidth).value;
      final savedH = prefs.getDouble(_keySizeHeight).value;
      final savedDisplayId = prefs.getString(_keyDisplayId).value;

      Rect? targetBounds;

      if (savedX != null &&
          savedY != null &&
          savedW != null &&
          savedH != null &&
          savedW > 0 &&
          savedH > 0) {
        final position = Offset(savedX, savedY);
        final size = Size(savedW, savedH);

        _logger.info(
            'Restoring saved state - Position: $position, Size: $size, Display ID: $savedDisplayId');

        // Pick a display to restore into (prefer saved display id)
        final displays = await screenRetriever.getAllDisplays();
        Display? target;

        if (savedDisplayId != null) {
          try {
            target = displays.firstWhere(
              (d) => d.id.toString() == savedDisplayId,
            );
            _logger.info('Found saved display: ${target.id}');
          } catch (e) {
            _logger
                .info('Saved display $savedDisplayId not found, using nearest');
          }
        }

        // Fallback to primary display or find nearest manually
        if (target == null) {
          if (displays.isNotEmpty) {
            // Find display that contains the window center (more accurate than top-left)
            final windowCenter = Offset(
              savedX + (savedW / 2),
              savedY + (savedH / 2),
            );
            for (final display in displays) {
              if (display.visiblePosition != null &&
                  display.visibleSize != null) {
                final displayRect = Rect.fromLTWH(
                  display.visiblePosition!.dx,
                  display.visiblePosition!.dy,
                  display.visibleSize!.width,
                  display.visibleSize!.height,
                );
                if (displayRect.contains(windowCenter)) {
                  target = display;
                  _logger.info(
                      'Found display containing window center: ${display.id}');
                  break;
                }
              }
            }
            // If no display contains the position, use primary
            if (target == null) {
              target = await screenRetriever.getPrimaryDisplay();
              _logger.info('Using primary display as fallback: ${target.id}');
            }
          } else {
            target = await screenRetriever.getPrimaryDisplay();
            _logger.info('Using primary display (only display): ${target.id}');
          }
        }

        // Get visible frame (accounts for taskbar/menu)
        final vf = Rect.fromLTWH(
          target.visiblePosition?.dx ?? 0,
          target.visiblePosition?.dy ?? 0,
          target.visibleSize?.width ?? target.size.width,
          target.visibleSize?.height ?? target.size.height,
        );

        // Use saved size, but cap to display size if needed
        // Also ensure minimum reasonable size
        final w = math.max(400.0, math.min(size.width, vf.width));
        final h = math.max(300.0, math.min(size.height, vf.height));

        // Use exact saved position - don't clamp!
        // This preserves negative coordinates for left monitors
        // Only adjust if window would be completely off-screen
        double x = savedX;
        double y = savedY;

        // Check if window would be at least partially visible
        final windowRect = Rect.fromLTWH(x, y, w, h);
        bool isVisible = false;

        // Check against all displays to see if window is at least partially visible
        for (final display in displays) {
          if (display.visiblePosition != null && display.visibleSize != null) {
            final displayRect = Rect.fromLTWH(
              display.visiblePosition!.dx,
              display.visiblePosition!.dy,
              display.visibleSize!.width,
              display.visibleSize!.height,
            );
            if (windowRect.overlaps(displayRect)) {
              isVisible = true;
              break;
            }
          }
        }

        // Only adjust if completely off-screen
        if (!isVisible) {
          _logger.warning(
              'Window would be off-screen, centering on target display');
          // Center on target display if completely off-screen
          x = vf.left + (vf.width - w) / 2;
          y = vf.top + (vf.height - h) / 2;
        }

        targetBounds = Rect.fromLTWH(x, y, w, h);

        _logger
            .info('Restoring window to: $targetBounds on display ${target.id}');
      } else {
        // No valid saved state, use default size and center
        _logger.info('No valid saved window state, using defaults');
        const defaultSize = Size(1200, 800);
        await windowManager.setSize(defaultSize);
        await windowManager.center();
      }

      // Apply geometry if we have it
      if (targetBounds != null) {
        await windowManager.setBounds(targetBounds);
      }

      // Restore state after geometry
      if (startMaximized.value || wasMax) {
        await windowManager.maximize();
        _logger.info('Restored window: maximized');
      } else if (wasFull) {
        await windowManager.setFullScreen(true);
        _logger.info('Restored window: fullscreen');
      }

      // Single delay for platform to settle
      await Future.delayed(const Duration(milliseconds: 150));
    } catch (e, st) {
      _logger.warning('Failed to restore window state, using defaults', e, st);
    } finally {
      _isRestoring = false;
      _logger.info('Window restoration complete');

      // Single final state update after restoration is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isInitialized) {
          _updateCurrentState();
        }
      });
    }
  }

  /// Reset window to center position with default size
  Future<void> resetWindowPosition() async {
    if (!_isInitialized) return;

    try {
      await _centerWindow();
      await _clearSavedState();
      _logger.info('Window position reset to center');
    } catch (e, stackTrace) {
      _logger.severe('Failed to reset window position', e, stackTrace);
    }
  }

  /// Update settings for window state persistence
  Future<void> updateSettings({
    bool? rememberState,
    bool? startMaximizedValue,
  }) async {
    final prefs = PreferencesService.instance;

    if (rememberState != null) {
      await prefs.setBool(_keyRememberState, rememberState);
      rememberWindowState.value = rememberState;
    }

    if (startMaximizedValue != null) {
      await prefs.setBool(_keyStartMaximized, startMaximizedValue);
      startMaximized.value = startMaximizedValue;
    }

    _logger.info(
        'Window state settings updated: remember=$rememberState, startMaximized=$startMaximizedValue');
  }

  /// Manually save current window state for testing/debugging
  Future<void> testSaveCurrentState() async {
    _logger.info('Manually saving current window state for testing');
    try {
      await _updateCurrentState();
      await _saveWindowState();
      _logger.info('Manual save completed successfully');
    } catch (e, stackTrace) {
      _logger.severe('Manual save failed', e, stackTrace);
    }
  }

  // WindowListener callbacks

  @override
  void onWindowResize() {
    if (!_isRestoring) {
      _logger.fine('Window resized, updating state');
      _updateStateAndSave();
    } else {
      _logger.fine('Window resized during restore, ignoring');
    }
  }

  @override
  void onWindowMove() {
    if (!_isRestoring) {
      _logger.fine('Window moved, updating state');
      _updateStateAndSave();
    } else {
      _logger.fine('Window moved during restore, ignoring');
    }
  }

  @override
  void onWindowMaximize() {
    isMaximized.value = true;
    _saveNow();
  }

  @override
  void onWindowUnmaximize() {
    isMaximized.value = false;
    _saveNow();
  }

  @override
  void onWindowMinimize() {
    isMinimized.value = true;
  }

  @override
  void onWindowRestore() {
    isMinimized.value = false;
  }

  @override
  void onWindowEnterFullScreen() {
    isFullScreen.value = true;
    _saveNow();
  }

  @override
  void onWindowLeaveFullScreen() {
    isFullScreen.value = false;
    _saveNow();
  }

  @override
  void onWindowClose() {
    _saveNow();
  }

  @override
  void onWindowFocus() {
    // No longer saving on focus - too noisy
  }

  @override
  void onWindowBlur() {
    // No longer saving on blur - too noisy
  }

  @override
  void onWindowEvent(String eventName) {
    // No longer handling generic events
  }

  // Private methods

  /// Load user preferences for window state
  Future<void> _loadPreferences() async {
    final prefs = PreferencesService.instance;

    rememberWindowState.value =
        prefs.getBool(_keyRememberState, defaultValue: true).value ?? true;
    startMaximized.value =
        prefs.getBool(_keyStartMaximized, defaultValue: false).value ?? false;
  }

  /// Update current window state from window manager
  Future<void> _updateCurrentState() async {
    try {
      final pos = await windowManager.getPosition();
      final size = await windowManager.getSize();
      final max = await windowManager.isMaximized();
      final min = await windowManager.isMinimized();
      final full = await windowManager.isFullScreen();

      windowPosition.value = pos;
      windowSize.value = size;
      isMaximized.value = max;
      isMinimized.value = min;
      isFullScreen.value = full;

      _logger.fine(
          'Updated current state - Pos: $pos, Size: $size, Max: $max, Full: $full');
    } catch (e) {
      _logger.warning('Failed to update current window state: $e');
    }
  }

  /// Update state and trigger debounced save
  void _updateStateAndSave() async {
    if (!rememberWindowState.value || _isRestoring) return;

    try {
      final max = await windowManager.isMaximized();
      final full = await windowManager.isFullScreen();

      // Only persist geometry when in "normal" state
      if (!max && !full) {
        final pos = await windowManager.getPosition();
        final size = await windowManager.getSize();

        _logger.fine('Updating window state - Position: $pos, Size: $size');

        windowPosition.value = pos;
        windowSize.value = size;
      }

      _debouncedSave();
    } catch (e) {
      _logger.warning('Failed to update window state: $e');
    }
  }

  /// Save window state with debouncing to avoid excessive writes
  void _debouncedSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_debounceDuration, _saveNow);
  }

  /// Save immediately
  void _saveNow() {
    _saveWindowState();
  }

  /// Save current window state to preferences
  Future<void> _saveWindowState() async {
    if (!_isInitialized || !rememberWindowState.value) return;

    try {
      final prefs = PreferencesService.instance;
      final max = await windowManager.isMaximized();
      final full = await windowManager.isFullScreen();

      await prefs.setBool(_keyMaximized, max);
      await prefs.setBool(_keyFullScreen, full);

      // Only save geometry in normal state
      if (!max && !full) {
        // Get fresh position and size directly from window manager
        final currentPos = await windowManager.getPosition();
        final currentSize = await windowManager.getSize();

        if (currentPos != null && currentSize != null) {
          _logger.fine(
              'Saving window state - Position: $currentPos, Size: $currentSize');

          await prefs.setDouble(_keyPositionX, currentPos.dx);
          await prefs.setDouble(_keyPositionY, currentPos.dy);
          await prefs.setDouble(_keySizeWidth, currentSize.width);
          await prefs.setDouble(_keySizeHeight, currentSize.height);

          // Save display ID
          try {
            final displays = await screenRetriever.getAllDisplays();
            Display? currentDisplay;

            // Find which display contains the window center (more accurate than top-left)
            final windowCenter = Offset(
              currentPos.dx + (currentSize.width / 2),
              currentPos.dy + (currentSize.height / 2),
            );
            for (final display in displays) {
              if (display.visiblePosition != null &&
                  display.visibleSize != null) {
                final displayRect = Rect.fromLTWH(
                  display.visiblePosition!.dx,
                  display.visiblePosition!.dy,
                  display.visibleSize!.width,
                  display.visibleSize!.height,
                );
                if (displayRect.contains(windowCenter)) {
                  currentDisplay = display;
                  _logger.fine('Window center on display: ${display.id}');
                  break;
                }
              }
            }

            // Fallback to primary display if position not in any display
            currentDisplay ??= await screenRetriever.getPrimaryDisplay();

            _logger.fine('Saving to display ID: ${currentDisplay.id}');
            await prefs.setString(_keyDisplayId, currentDisplay.id.toString());
          } catch (e) {
            _logger.warning('Failed to save display ID: $e');
          }
        } else {
          _logger.warning('Cannot save window state: position or size is null');
        }
      }

      _logger.info('Window state saved successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to save window state', e, stackTrace);
    }
  }

  /// Center window on screen
  Future<void> _centerWindow() async {
    const defaultSize = Size(1200, 800);
    await windowManager.setSize(defaultSize);
    await windowManager.center();
  }

  /// Clear all saved window state
  Future<void> _clearSavedState() async {
    final prefs = PreferencesService.instance;

    await Future.wait([
      prefs.remove(_keyPositionX),
      prefs.remove(_keyPositionY),
      prefs.remove(_keySizeWidth),
      prefs.remove(_keySizeHeight),
      prefs.remove(_keyMaximized),
      prefs.remove(_keyFullScreen),
      prefs.remove(_keyDisplayId),
    ]);
  }
}

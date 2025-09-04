import 'dart:math';
import 'package:flutter/material.dart';

/// Model for action sheet items with platform-specific styling
class AdaptiveActionSheetItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool isDestructive;
  final bool isDefault;
  final bool enabled;

  const AdaptiveActionSheetItem({
    required this.value,
    required this.label,
    this.icon,
    this.isDestructive = false,
    this.isDefault = false,
    this.enabled = true,
  });
}

/// Model for dialog action buttons
class AdaptiveDialogAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isDefault;
  final bool enabled;

  const AdaptiveDialogAction({
    required this.label,
    this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
    this.enabled = true,
  });
}

/// Helper class for responsive dialog behavior
class DialogResponsiveness {
  /// Determines if full-screen should be used based on screen size
  static bool shouldUseFullScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 600 || size.height < 600;
  }

  /// Gets appropriate dialog width based on screen size
  static double getDialogWidth(BuildContext context, {double? requested}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // Mobile: 90% of screen width
      return screenWidth * 0.9;
    } else if (screenWidth < 1200) {
      // Tablet: use requested width if provided, otherwise 70% of screen
      if (requested != null) {
        return min(requested,
            screenWidth * 0.9); // Allow requested width but cap at 90% screen
      }
      return min(700, screenWidth * 0.7);
    } else {
      // Desktop: requested width or default 700px
      return requested ?? 700;
    }
  }

  /// Gets appropriate dialog max height
  static double getDialogMaxHeight(BuildContext context, {double? requested}) {
    final screenHeight = MediaQuery.of(context).size.height;
    return requested ?? screenHeight * 0.85;
  }

  /// Gets appropriate dialog padding based on screen size
  static EdgeInsets getDialogPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // Mobile: smaller padding
      return const EdgeInsets.all(16);
    } else {
      // Desktop/Tablet: larger padding
      return const EdgeInsets.all(24);
    }
  }

  /// Determines if the device is mobile
  static bool isMobile(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 600;
  }

  /// Determines if the device is tablet
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 600 && size.width < 1200;
  }

  /// Determines if the device is desktop
  static bool isDesktop(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 1200;
  }
}

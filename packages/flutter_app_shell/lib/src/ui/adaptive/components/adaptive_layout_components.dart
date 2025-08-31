import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../adaptive_style_provider.dart';

/// Adaptive tabs that can be placed at different positions
class AdaptiveTabs extends StatelessWidget {
  final List<AdaptiveTab> tabs;
  final int currentIndex;
  final Function(int) onTabSelected;
  final TabPlacement placement;
  final bool enabled;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final double? indicatorWeight;
  final EdgeInsetsGeometry? padding;
  final bool isScrollable;

  const AdaptiveTabs({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    this.placement = TabPlacement.top,
    this.enabled = true,
    this.backgroundColor,
    this.indicatorColor,
    this.indicatorWeight,
    this.padding,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertinoTabs(context, styleProvider);
      case AdaptivePlatform.forui:
        return _buildForuiTabs(context, styleProvider);
      default:
        return _buildMaterialTabs(context, styleProvider);
    }
  }

  Widget _buildMaterialTabs(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    if (placement == TabPlacement.bottom) {
      return _buildBottomNavigationBar(context, theme);
    }

    Widget tabBar = TabBar(
      tabs: tabs
          .map((tab) => Tab(
                text: tab.label,
                icon: tab.icon != null ? Icon(tab.icon!) : null,
              ))
          .toList(),
      onTap: enabled ? onTabSelected : null,
      isScrollable: isScrollable,
      indicatorColor: indicatorColor ?? theme.colorScheme.primary,
      indicatorWeight: indicatorWeight ?? 2.0,
      labelColor: enabled ? theme.colorScheme.primary : theme.disabledColor,
      unselectedLabelColor:
          enabled ? theme.colorScheme.onSurfaceVariant : theme.disabledColor,
      padding: padding,
    );

    if (placement == TabPlacement.side) {
      return RotatedBox(
        quarterTurns: placement == TabPlacement.left ? 3 : 1,
        child: tabBar,
      );
    }

    return tabBar;
  }

  Widget _buildCupertinoTabs(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    if (placement == TabPlacement.bottom) {
      return _buildCupertinoBottomTabBar(context);
    }

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ??
            CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: isScrollable
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceEvenly,
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == currentIndex;

          return Expanded(
            flex: isScrollable ? 0 : 1,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: enabled ? () => onTabSelected(index) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.icon != null)
                    Icon(
                      tab.icon!,
                      color: isSelected
                          ? CupertinoColors.activeBlue.resolveFrom(context)
                          : (enabled
                              ? CupertinoColors.inactiveGray
                                  .resolveFrom(context)
                              : CupertinoColors.tertiaryLabel
                                  .resolveFrom(context)),
                      size: 20,
                    ),
                  if (tab.icon != null && tab.label != null)
                    const SizedBox(height: 4),
                  if (tab.label != null)
                    Text(
                      tab.label!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.w400,
                        color: isSelected
                            ? CupertinoColors.activeBlue.resolveFrom(context)
                            : (enabled
                                ? CupertinoColors.label.resolveFrom(context)
                                : CupertinoColors.tertiaryLabel
                                    .resolveFrom(context)),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildForuiTabs(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    if (placement == TabPlacement.bottom) {
      return _buildForuiBottomTabBar(context, theme);
    }

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: isScrollable
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceEvenly,
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == currentIndex;

          return Expanded(
            flex: isScrollable ? 0 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? () => onTabSelected(index) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tab.icon != null)
                        Icon(
                          tab.icon,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (enabled
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5)),
                          size: 20,
                        ),
                      if (tab.icon != null && tab.label != null)
                        const SizedBox(height: 6),
                      if (tab.label != null)
                        Text(
                          tab.label!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (enabled
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: enabled ? onTabSelected : null,
      backgroundColor: backgroundColor,
      selectedItemColor: indicatorColor ?? theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurfaceVariant,
      type: tabs.length > 3
          ? BottomNavigationBarType.shifting
          : BottomNavigationBarType.fixed,
      items: tabs
          .map((tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon ?? Icons.tab),
                label: tab.label ?? '',
              ))
          .toList(),
    );
  }

  Widget _buildCupertinoBottomTabBar(BuildContext context) {
    return CupertinoTabBar(
      currentIndex: currentIndex,
      onTap: enabled ? onTabSelected : null,
      backgroundColor: backgroundColor,
      activeColor: indicatorColor ?? CupertinoColors.activeBlue,
      inactiveColor: CupertinoColors.inactiveGray,
      items: tabs
          .map((tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon ?? CupertinoIcons.circle),
                label: tab.label ?? '',
              ))
          .toList(),
    );
  }

  Widget _buildForuiBottomTabBar(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = index == currentIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: enabled ? () => onTabSelected(index) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tab.icon != null)
                            Icon(
                              tab.icon,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (enabled
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5)),
                              size: 24,
                            ),
                          if (tab.icon != null && tab.label != null)
                            const SizedBox(height: 2),
                          if (tab.label != null)
                            Text(
                              tab.label!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (enabled
                                        ? theme.colorScheme.onSurfaceVariant
                                        : theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5)),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Stepper component for sequential workflows
class AdaptiveStepper extends StatelessWidget {
  final List<AdaptiveStep> steps;
  final int currentStep;
  final Function(int)? onStepTapped;
  final VoidCallback? onStepContinue;
  final VoidCallback? onStepCancel;
  final StepperType type;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? contentPadding;

  const AdaptiveStepper({
    super.key,
    required this.steps,
    this.currentStep = 0,
    this.onStepTapped,
    this.onStepContinue,
    this.onStepCancel,
    this.type = StepperType.vertical,
    this.margin,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertinoStepper(context, styleProvider);
      case AdaptivePlatform.forui:
        return _buildForuiStepper(context, styleProvider);
      default:
        return _buildMaterialStepper(context, styleProvider);
    }
  }

  Widget _buildMaterialStepper(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    return Stepper(
      steps: steps
          .map((step) => Step(
                title: Text(step.title),
                content: step.content ?? const SizedBox.shrink(),
                isActive: step.isActive,
                state: step.state,
              ))
          .toList(),
      currentStep: currentStep,
      onStepTapped: onStepTapped,
      onStepContinue: onStepContinue,
      onStepCancel: onStepCancel,
      type: type,
      margin: margin,
      controlsBuilder: (context, details) {
        return const SizedBox.shrink(); // Simplified controls
      },
    );
  }

  Widget _buildCupertinoStepper(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    return Container(
      margin: margin,
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;
          final isCurrent = index == currentStep;
          final isCompleted = index < currentStep;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step header
              GestureDetector(
                onTap: onStepTapped != null ? () => onStepTapped!(index) : null,
                child: Container(
                  padding: contentPadding ?? const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Step indicator
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted || isCurrent
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey4,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  CupertinoIcons.checkmark,
                                  color: CupertinoColors.white,
                                  size: 16,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent
                                        ? CupertinoColors.white
                                        : CupertinoColors.secondaryLabel,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Step title
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.w400,
                            color: isCurrent
                                ? CupertinoColors.label
                                : CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Step content
              if (isCurrent && step.content != null)
                Container(
                  margin:
                      const EdgeInsets.only(left: 40, right: 16, bottom: 16),
                  child: step.content,
                ),

              // Connector line
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(left: 29),
                  width: 1,
                  height: 20,
                  color: isCompleted
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.separator,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildForuiStepper(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;
          final isCurrent = index == currentStep;
          final isCompleted = index < currentStep;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step header
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      onStepTapped != null ? () => onStepTapped!(index) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: contentPadding ?? const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Step indicator
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted || isCurrent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHigh,
                            border: Border.all(
                              color: isCompleted || isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    color: theme.colorScheme.onPrimary,
                                    size: 18,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isCurrent
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Step title
                        Expanded(
                          child: Text(
                            step.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight:
                                  isCurrent ? FontWeight.w600 : FontWeight.w500,
                              color: isCurrent
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Step content
              if (isCurrent && step.content != null)
                Container(
                  margin:
                      const EdgeInsets.only(left: 48, right: 16, bottom: 16),
                  child: step.content,
                ),

              // Connector line
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(left: 31),
                  width: 2,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Data models for tabs and steps
class AdaptiveTab {
  final String? label;
  final IconData? icon;
  final Widget? content;
  final bool enabled;

  const AdaptiveTab({
    this.label,
    this.icon,
    this.content,
    this.enabled = true,
  });
}

class AdaptiveStep {
  final String title;
  final Widget? content;
  final bool isActive;
  final StepState state;
  final Widget Function(BuildContext, ControlsDetails)? controlsBuilder;

  const AdaptiveStep({
    required this.title,
    this.content,
    this.isActive = false,
    this.state = StepState.indexed,
    this.controlsBuilder,
  });
}

enum TabPlacement {
  top,
  bottom,
  left,
  right,
  side,
}

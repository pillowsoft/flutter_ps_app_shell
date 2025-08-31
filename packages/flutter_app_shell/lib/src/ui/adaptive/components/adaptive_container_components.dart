import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../adaptive_style_provider.dart';

/// Adaptive bottom sheet that follows platform conventions
class AdaptiveBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
    double? elevation,
    Color? backgroundColor,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
  }) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _showCupertinoBottomSheet<T>(
          context: context,
          child: child,
          isDismissible: isDismissible,
          backgroundColor: backgroundColor,
          barrierColor: barrierColor ?? Colors.black54,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
        );
      case AdaptivePlatform.forui:
        return _showForuiBottomSheet<T>(
          context: context,
          child: child,
          isDismissible: isDismissible,
          enableDrag: enableDrag,
          isScrollControlled: isScrollControlled,
          elevation: elevation,
          backgroundColor: backgroundColor,
          barrierColor: barrierColor ?? Colors.black54,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
        );
      default:
        return showModalBottomSheet<T>(
          context: context,
          builder: (context) => child,
          isDismissible: isDismissible,
          enableDrag: enableDrag,
          isScrollControlled: isScrollControlled,
          elevation: elevation,
          backgroundColor: backgroundColor,
          barrierColor: barrierColor ?? Colors.black54,
          barrierLabel: barrierLabel,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
          transitionAnimationController: transitionAnimationController,
          anchorPoint: anchorPoint,
        );
    }
  }

  static Future<T?> _showCupertinoBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    Color? backgroundColor,
    Color? barrierColor,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      barrierColor: barrierColor ?? Colors.black54,
      barrierDismissible: isDismissible,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor ??
              CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }

  static Future<T?> _showForuiBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
    double? elevation,
    Color? backgroundColor,
    Color? barrierColor,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      elevation: elevation ?? 0,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black54,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle for ForUI style
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Expandable card component
class AdaptiveExpandableCard extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget content;
  final Widget? leading;
  final Widget? trailing;
  final bool initiallyExpanded;
  final Function(bool)? onExpansionChanged;
  final EdgeInsetsGeometry? tilePadding;
  final EdgeInsetsGeometry? childrenPadding;
  final Color? backgroundColor;
  final Color? collapsedBackgroundColor;
  final ShapeBorder? shape;
  final Clip clipBehavior;
  final ListTileControlAffinity controlAffinity;
  final Duration animationDuration;
  final bool maintainState;

  const AdaptiveExpandableCard({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
    this.leading,
    this.trailing,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.tilePadding,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.shape,
    this.clipBehavior = Clip.none,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.animationDuration = const Duration(milliseconds: 200),
    this.maintainState = false,
  });

  @override
  State<AdaptiveExpandableCard> createState() => _AdaptiveExpandableCardState();
}

class _AdaptiveExpandableCardState extends State<AdaptiveExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertinoExpandableCard(context, styleProvider);
      case AdaptivePlatform.forui:
        return _buildForuiExpandableCard(context, styleProvider);
      default:
        return _buildMaterialExpandableCard(context, styleProvider);
    }
  }

  Widget _buildMaterialExpandableCard(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    return ExpansionTile(
      title: widget.title,
      subtitle: widget.subtitle,
      leading: widget.leading,
      trailing: widget.trailing,
      initiallyExpanded: widget.initiallyExpanded,
      onExpansionChanged: widget.onExpansionChanged,
      tilePadding: widget.tilePadding,
      childrenPadding: widget.childrenPadding,
      backgroundColor: widget.backgroundColor,
      collapsedBackgroundColor: widget.collapsedBackgroundColor,
      shape: widget.shape,
      clipBehavior: widget.clipBehavior,
      controlAffinity: widget.controlAffinity,
      maintainState: widget.maintainState,
      children: [widget.content],
    );
  }

  Widget _buildCupertinoExpandableCard(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    return Container(
      decoration: BoxDecoration(
        color: _isExpanded
            ? (widget.backgroundColor ??
                CupertinoColors.systemBackground.resolveFrom(context))
            : (widget.collapsedBackgroundColor ??
                CupertinoColors.systemGrey6.resolveFrom(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CupertinoButton(
            padding: widget.tilePadding ?? const EdgeInsets.all(16),
            onPressed: _toggleExpansion,
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.title,
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        widget.subtitle!,
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 12),
                  widget.trailing!,
                ] else
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: widget.animationDuration,
                    child: const Icon(
                      CupertinoIcons.chevron_down,
                      size: 20,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: widget.animationDuration,
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    width: double.infinity,
                    padding: widget.childrenPadding ??
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: widget.content,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildForuiExpandableCard(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _isExpanded
            ? (widget.backgroundColor ?? theme.colorScheme.surface)
            : (widget.collapsedBackgroundColor ??
                theme.colorScheme.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpansion,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: widget.tilePadding ?? const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle(
                            style: theme.textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            child: widget.title,
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 4),
                            DefaultTextStyle(
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              child: widget.subtitle!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 12),
                      widget.trailing!,
                    ] else
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: widget.animationDuration,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: widget.animationDuration,
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    width: double.infinity,
                    padding: widget.childrenPadding ??
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: widget.content,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    widget.onExpansionChanged?.call(_isExpanded);
  }
}

/// Expandable list widget
class AdaptiveExpandableList extends StatelessWidget {
  final List<AdaptiveExpandableListItem> items;
  final EdgeInsetsGeometry? padding;
  final bool allowMultipleExpanded;
  final List<int>? initiallyExpandedIndexes;
  final Function(int, bool)? onExpansionChanged;

  const AdaptiveExpandableList({
    super.key,
    required this.items,
    this.padding,
    this.allowMultipleExpanded = false,
    this.initiallyExpandedIndexes,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (allowMultipleExpanded) {
      return ListView.separated(
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return AdaptiveExpandableCard(
            title: Text(item.title),
            subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
            content: item.content,
            leading: item.leading,
            trailing: item.trailing,
            initiallyExpanded:
                initiallyExpandedIndexes?.contains(index) ?? false,
            onExpansionChanged: (expanded) =>
                onExpansionChanged?.call(index, expanded),
          );
        },
      );
    }

    return ExpansionPanelList(
      expansionCallback: (panelIndex, isExpanded) {
        onExpansionChanged?.call(panelIndex, !isExpanded);
      },
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return ExpansionPanel(
          headerBuilder: (context, isExpanded) => ListTile(
            title: Text(item.title),
            subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
            leading: item.leading,
            trailing: item.trailing,
          ),
          body: item.content,
          isExpanded: initiallyExpandedIndexes?.contains(index) ?? false,
        );
      }).toList(),
    );
  }
}

/// Accordion-style expandable component
class AdaptiveAccordion extends StatefulWidget {
  final List<AdaptiveAccordionSection> sections;
  final bool allowMultipleExpanded;
  final List<int>? initiallyExpandedIndexes;
  final Function(int, bool)? onExpansionChanged;
  final EdgeInsetsGeometry? sectionSpacing;
  final EdgeInsetsGeometry? contentPadding;

  const AdaptiveAccordion({
    super.key,
    required this.sections,
    this.allowMultipleExpanded = false,
    this.initiallyExpandedIndexes,
    this.onExpansionChanged,
    this.sectionSpacing,
    this.contentPadding,
  });

  @override
  State<AdaptiveAccordion> createState() => _AdaptiveAccordionState();
}

class _AdaptiveAccordionState extends State<AdaptiveAccordion> {
  late Set<int> _expandedSections;

  @override
  void initState() {
    super.initState();
    _expandedSections = Set.from(widget.initiallyExpandedIndexes ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.sections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;
        final isExpanded = _expandedSections.contains(index);

        return Padding(
          padding: widget.sectionSpacing ?? const EdgeInsets.only(bottom: 8),
          child: AdaptiveExpandableCard(
            title: Text(section.title),
            subtitle: section.subtitle != null ? Text(section.subtitle!) : null,
            content: section.content,
            leading: section.leading,
            trailing: section.trailing,
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) =>
                _handleExpansionChanged(index, expanded),
            childrenPadding: widget.contentPadding,
          ),
        );
      }).toList(),
    );
  }

  void _handleExpansionChanged(int index, bool expanded) {
    setState(() {
      if (expanded) {
        if (!widget.allowMultipleExpanded) {
          _expandedSections.clear();
        }
        _expandedSections.add(index);
      } else {
        _expandedSections.remove(index);
      }
    });

    widget.onExpansionChanged?.call(index, expanded);
  }
}

/// Data models for expandable components
class AdaptiveExpandableListItem {
  final String title;
  final String? subtitle;
  final Widget content;
  final Widget? leading;
  final Widget? trailing;

  const AdaptiveExpandableListItem({
    required this.title,
    required this.content,
    this.subtitle,
    this.leading,
    this.trailing,
  });
}

class AdaptiveAccordionSection {
  final String title;
  final String? subtitle;
  final Widget content;
  final Widget? leading;
  final Widget? trailing;

  const AdaptiveAccordionSection({
    required this.title,
    required this.content,
    this.subtitle,
    this.leading,
    this.trailing,
  });
}

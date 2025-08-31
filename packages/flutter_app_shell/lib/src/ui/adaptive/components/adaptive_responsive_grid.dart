import 'package:flutter/material.dart';
import '../adaptive_style_provider.dart';

/// Responsive grid system with breakpoint management
class AdaptiveResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final Map<Breakpoint, int> columns;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final Axis scrollDirection;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const AdaptiveResponsiveGrid({
    super.key,
    required this.children,
    required this.columns,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentBreakpoint = _getBreakpoint(constraints.maxWidth);
        final columnCount =
            columns[currentBreakpoint] ?? columns[Breakpoint.mobile] ?? 1;

        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: _calculateAspectRatio(currentBreakpoint),
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
          scrollDirection: scrollDirection,
          shrinkWrap: shrinkWrap,
          physics: physics,
          controller: controller,
        );
      },
    );
  }

  Breakpoint _getBreakpoint(double width) {
    if (width >= 1200) return Breakpoint.desktop;
    if (width >= 768) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }

  double _calculateAspectRatio(Breakpoint breakpoint) {
    switch (breakpoint) {
      case Breakpoint.desktop:
        return 1.2;
      case Breakpoint.tablet:
        return 1.1;
      case Breakpoint.mobile:
        return 1.0;
    }
  }
}

/// Staggered grid for items of varying heights
class AdaptiveStaggeredGrid extends StatelessWidget {
  final List<AdaptiveStaggeredGridItem> children;
  final Map<Breakpoint, int> columns;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const AdaptiveStaggeredGrid({
    super.key,
    required this.children,
    required this.columns,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentBreakpoint = _getBreakpoint(constraints.maxWidth);
        final columnCount =
            columns[currentBreakpoint] ?? columns[Breakpoint.mobile] ?? 1;

        // Create columns for staggered layout
        final columnChildren = <List<Widget>>[];
        for (int i = 0; i < columnCount; i++) {
          columnChildren.add(<Widget>[]);
        }

        // Distribute items across columns
        for (int i = 0; i < children.length; i++) {
          final columnIndex = i % columnCount;
          columnChildren[columnIndex].add(
            Padding(
              padding: EdgeInsets.only(bottom: runSpacing),
              child: children[i].child,
            ),
          );
        }

        return SingleChildScrollView(
          controller: controller,
          physics: physics,
          scrollDirection: scrollDirection,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columnChildren.asMap().entries.map((entry) {
                final index = entry.key;
                final columnItems = entry.value;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index > 0 ? spacing / 2 : 0,
                      right: index < columnCount - 1 ? spacing / 2 : 0,
                    ),
                    child: Column(
                      children: columnItems,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Breakpoint _getBreakpoint(double width) {
    if (width >= 1200) return Breakpoint.desktop;
    if (width >= 768) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }
}

/// Masonry layout for Pinterest-style grids
class AdaptiveMasonryGrid extends StatelessWidget {
  final List<Widget> children;
  final Map<Breakpoint, int> columns;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  const AdaptiveMasonryGrid({
    super.key,
    required this.children,
    required this.columns,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
    this.controller,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentBreakpoint = _getBreakpoint(constraints.maxWidth);
        final columnCount =
            columns[currentBreakpoint] ?? columns[Breakpoint.mobile] ?? 1;

        return _MasonryLayout(
          columnCount: columnCount,
          spacing: spacing,
          runSpacing: runSpacing,
          padding: padding,
          controller: controller,
          physics: physics,
          children: children,
        );
      },
    );
  }

  Breakpoint _getBreakpoint(double width) {
    if (width >= 1200) return Breakpoint.desktop;
    if (width >= 768) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }
}

class _MasonryLayout extends StatefulWidget {
  final int columnCount;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final List<Widget> children;

  const _MasonryLayout({
    required this.columnCount,
    required this.spacing,
    required this.runSpacing,
    required this.children,
    this.padding,
    this.controller,
    this.physics,
  });

  @override
  State<_MasonryLayout> createState() => _MasonryLayoutState();
}

class _MasonryLayoutState extends State<_MasonryLayout> {
  final List<GlobalKey> _keys = [];
  final List<double> _columnHeights = [];

  @override
  void initState() {
    super.initState();
    _initializeKeys();
  }

  void _initializeKeys() {
    _keys.clear();
    _columnHeights.clear();

    for (int i = 0; i < widget.children.length; i++) {
      _keys.add(GlobalKey());
    }

    for (int i = 0; i < widget.columnCount; i++) {
      _columnHeights.add(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.controller,
      physics: widget.physics,
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnWidth = (constraints.maxWidth -
                    (widget.spacing * (widget.columnCount - 1))) /
                widget.columnCount;

            return _buildMasonryLayout(columnWidth);
          },
        ),
      ),
    );
  }

  Widget _buildMasonryLayout(double columnWidth) {
    final columnChildren = <List<Widget>>[];
    for (int i = 0; i < widget.columnCount; i++) {
      columnChildren.add(<Widget>[]);
    }

    _columnHeights.fillRange(0, widget.columnCount, 0.0);

    for (int i = 0; i < widget.children.length; i++) {
      final shortestColumnIndex = _getShortestColumnIndex();

      columnChildren[shortestColumnIndex].add(
        Container(
          key: _keys[i],
          width: columnWidth,
          margin: EdgeInsets.only(bottom: widget.runSpacing),
          child: widget.children[i],
        ),
      );

      // Estimate height for layout (this is a simplified approach)
      _columnHeights[shortestColumnIndex] += 200 + widget.runSpacing;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columnChildren.asMap().entries.map((entry) {
        final index = entry.key;
        final items = entry.value;

        return SizedBox(
          width: columnWidth,
          child: Padding(
            padding: EdgeInsets.only(
              right: index < widget.columnCount - 1 ? widget.spacing : 0,
            ),
            child: Column(
              children: items,
            ),
          ),
        );
      }).toList(),
    );
  }

  int _getShortestColumnIndex() {
    double minHeight = _columnHeights[0];
    int minIndex = 0;

    for (int i = 1; i < _columnHeights.length; i++) {
      if (_columnHeights[i] < minHeight) {
        minHeight = _columnHeights[i];
        minIndex = i;
      }
    }

    return minIndex;
  }
}

/// Breakpoint-aware container
class AdaptiveBreakpointContainer extends StatelessWidget {
  final Map<Breakpoint, Widget> children;
  final Widget? fallback;

  const AdaptiveBreakpointContainer({
    super.key,
    required this.children,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentBreakpoint = _getBreakpoint(constraints.maxWidth);

        return children[currentBreakpoint] ??
            children[Breakpoint.mobile] ??
            fallback ??
            const SizedBox.shrink();
      },
    );
  }

  Breakpoint _getBreakpoint(double width) {
    if (width >= 1200) return Breakpoint.desktop;
    if (width >= 768) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }
}

/// Adaptive flex that changes direction based on breakpoint
class AdaptiveBreakpointFlex extends StatelessWidget {
  final List<Widget> children;
  final Map<Breakpoint, Axis> direction;
  final Map<Breakpoint, MainAxisAlignment>? mainAxisAlignment;
  final Map<Breakpoint, CrossAxisAlignment>? crossAxisAlignment;
  final Map<Breakpoint, MainAxisSize>? mainAxisSize;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  const AdaptiveBreakpointFlex({
    super.key,
    required this.children,
    required this.direction,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.mainAxisSize,
    this.padding,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentBreakpoint = _getBreakpoint(constraints.maxWidth);
        final currentDirection = direction[currentBreakpoint] ??
            direction[Breakpoint.mobile] ??
            Axis.vertical;
        final currentMainAxisAlignment =
            mainAxisAlignment?[currentBreakpoint] ?? MainAxisAlignment.start;
        final currentCrossAxisAlignment =
            crossAxisAlignment?[currentBreakpoint] ?? CrossAxisAlignment.center;
        final currentMainAxisSize =
            mainAxisSize?[currentBreakpoint] ?? MainAxisSize.max;

        Widget content;
        if (currentDirection == Axis.horizontal) {
          content = Row(
            mainAxisAlignment: currentMainAxisAlignment,
            crossAxisAlignment: currentCrossAxisAlignment,
            mainAxisSize: currentMainAxisSize,
            children: _addSpacing(children, currentDirection),
          );
        } else {
          content = Column(
            mainAxisAlignment: currentMainAxisAlignment,
            crossAxisAlignment: currentCrossAxisAlignment,
            mainAxisSize: currentMainAxisSize,
            children: _addSpacing(children, currentDirection),
          );
        }

        if (padding != null) {
          content = Padding(padding: padding!, child: content);
        }

        return content;
      },
    );
  }

  List<Widget> _addSpacing(List<Widget> children, Axis direction) {
    if (children.isEmpty) return children;

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          direction == Axis.horizontal
              ? SizedBox(width: spacing)
              : SizedBox(height: spacing),
        );
      }
    }
    return result;
  }

  Breakpoint _getBreakpoint(double width) {
    if (width >= 1200) return Breakpoint.desktop;
    if (width >= 768) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }
}

/// Utility class for responsive values
class AdaptiveResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const AdaptiveResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  T getValue(BuildContext context) {
    return getValueForWidth(MediaQuery.of(context).size.width);
  }

  T getValueForWidth(double width) {
    if (width >= 1200 && desktop != null) return desktop!;
    if (width >= 768 && tablet != null) return tablet!;
    return mobile;
  }
}

/// Extension methods for responsive design
extension ResponsiveContext on BuildContext {
  Breakpoint get breakpoint {
    final width = MediaQuery.of(this).size.width;
    if (width >= 1200) return Breakpoint.desktop;
    if (width >= 768) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }

  bool get isMobile => breakpoint == Breakpoint.mobile;
  bool get isTablet => breakpoint == Breakpoint.tablet;
  bool get isDesktop => breakpoint == Breakpoint.desktop;

  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (breakpoint) {
      case Breakpoint.desktop:
        return desktop ?? tablet ?? mobile;
      case Breakpoint.tablet:
        return tablet ?? mobile;
      case Breakpoint.mobile:
        return mobile;
    }
  }
}

/// Data models and enums
enum Breakpoint {
  mobile, // < 768px
  tablet, // 768px - 1199px
  desktop, // >= 1200px
}

class AdaptiveStaggeredGridItem {
  final Widget child;
  final int crossAxisCellCount;
  final int mainAxisCellCount;

  const AdaptiveStaggeredGridItem({
    required this.child,
    this.crossAxisCellCount = 1,
    this.mainAxisCellCount = 1,
  });
}

/// Grid utilities
class AdaptiveGridUtils {
  static const Map<Breakpoint, int> defaultColumns = {
    Breakpoint.mobile: 1,
    Breakpoint.tablet: 2,
    Breakpoint.desktop: 3,
  };

  static const Map<Breakpoint, int> twoColumnGrid = {
    Breakpoint.mobile: 1,
    Breakpoint.tablet: 2,
    Breakpoint.desktop: 2,
  };

  static const Map<Breakpoint, int> fourColumnGrid = {
    Breakpoint.mobile: 2,
    Breakpoint.tablet: 3,
    Breakpoint.desktop: 4,
  };

  static const Map<Breakpoint, int> sixColumnGrid = {
    Breakpoint.mobile: 2,
    Breakpoint.tablet: 4,
    Breakpoint.desktop: 6,
  };

  static Map<Breakpoint, int> customColumns({
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return {
      Breakpoint.mobile: mobile,
      Breakpoint.tablet: tablet,
      Breakpoint.desktop: desktop,
    };
  }

  static double getBreakpointWidth(Breakpoint breakpoint) {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return 767;
      case Breakpoint.tablet:
        return 1199;
      case Breakpoint.desktop:
        return 1200;
    }
  }

  static Breakpoint getBreakpointForWidth(double width) {
    if (width >= 1200) return Breakpoint.desktop;
    if (width >= 768) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }
}

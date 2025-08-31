import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import '../../models/sample_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late DashboardMetrics _metrics;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _metrics = SampleData.generateMetrics();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _metrics = SampleData.generateMetrics();
      _isRefreshing = false;
    });

    // Replay animation
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);
      final styles = context.adaptiveStyle;

      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          key: ValueKey('dashboard_scroll_$uiSystem'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with refresh button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: styles.headlineLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Real-time business metrics and insights',
                            style: styles.bodyLarge.copyWith(
                              color: styles.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isRefreshing ? null : _refreshData,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Last updated indicator
                Text(
                  'Last updated: ${_formatTimestamp(_metrics.lastUpdated)}',
                  style: styles.bodySmall.copyWith(
                    color: styles.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                // Metrics grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = _getGridCount(constraints.maxWidth);
                    final itemWidth =
                        (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                            crossAxisCount;
                    final itemHeight = itemWidth * 0.6;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: itemWidth / itemHeight,
                      children: [
                        _buildAnimatedMetricCard(
                          context,
                          ui,
                          styles,
                          'Active Users',
                          _formatNumber(_metrics.activeUsers.toDouble()),
                          ui.getIcon('people'),
                          Colors.blue,
                          _metrics.activeUsers / 1500.0,
                          0,
                        ),
                        _buildAnimatedMetricCard(
                          context,
                          ui,
                          styles,
                          'Revenue',
                          '\$${_formatCurrency(_metrics.revenue)}',
                          Icons.attach_money,
                          Colors.green,
                          _metrics.revenue / 60000.0,
                          100,
                        ),
                        _buildAnimatedMetricCard(
                          context,
                          ui,
                          styles,
                          'Growth',
                          '+${(_metrics.growth * 100).toStringAsFixed(1)}%',
                          Icons.trending_up,
                          Colors.orange,
                          _metrics.growth,
                          200,
                        ),
                        _buildAnimatedMetricCard(
                          context,
                          ui,
                          styles,
                          'Performance',
                          '${(_metrics.performance * 100).toStringAsFixed(1)}%',
                          Icons.speed,
                          Colors.purple,
                          _metrics.performance,
                          300,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Recent projects section
                _buildRecentProjects(ui, styles),

                const SizedBox(height: 32),

                // Quick actions
                _buildQuickActions(ui, styles),
              ],
            ),
          ),
        ),
      );
    });
  }

  int _getGridCount(double width) {
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildAnimatedMetricCard(
    BuildContext context,
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    String title,
    String value,
    IconData icon,
    Color color,
    double progress,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return ui.card(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: styles.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: animatedProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: styles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: styles.bodyMedium.copyWith(
                  color: styles.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentProjects(
      AdaptiveWidgetFactory ui, AdaptiveStyleProvider styles) {
    final projects = SampleData.sampleProjects.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Projects',
              style: styles.titleLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            ui.textButton(
              label: 'View All',
              onPressed: () {
                final nav = getIt<NavigationService>();
                nav.go(
                    '/services'); // Navigate to a projects screen when available
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projects.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final project = projects[index];
            return _buildProjectCard(ui, styles, project);
          },
        ),
      ],
    );
  }

  Widget _buildProjectCard(
      AdaptiveWidgetFactory ui, AdaptiveStyleProvider styles, Project project) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getProjectColor(project.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProjectIcon(project.category),
              color: _getProjectColor(project.category),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style:
                      styles.titleMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  project.description,
                  style:
                      styles.bodySmall.copyWith(color: styles.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip(styles, project.status),
                    const SizedBox(width: 12),
                    Text(
                      '${(project.progress * 100).round()}% complete',
                      style: styles.bodySmall
                          .copyWith(color: styles.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircularProgressIndicator(
            value: project.progress,
            backgroundColor: styles.surfaceVariant,
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AdaptiveStyleProvider styles, ProjectStatus status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: styles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildQuickActions(
      AdaptiveWidgetFactory ui, AdaptiveStyleProvider styles) {
    final actions = [
      _QuickAction(
        title: 'Create Project',
        icon: Icons.add_box,
        color: Colors.blue,
        onTap: () => _showCreateProjectDialog(),
      ),
      _QuickAction(
        title: 'View Analytics',
        icon: Icons.analytics,
        color: Colors.green,
        onTap: () {
          final nav = getIt<NavigationService>();
          nav.go('/services');
        },
      ),
      _QuickAction(
        title: 'Team Chat',
        icon: Icons.chat_bubble,
        color: Colors.orange,
        onTap: () => _showComingSoonSnackBar(),
      ),
      _QuickAction(
        title: 'Settings',
        icon: Icons.settings,
        color: Colors.purple,
        onTap: () {
          final nav = getIt<NavigationService>();
          nav.go('/settings');
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: styles.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildQuickActionCard(ui, styles, action);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(AdaptiveWidgetFactory ui,
      AdaptiveStyleProvider styles, _QuickAction action) {
    return ui.card(
      onTap: action.onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              action.icon,
              color: action.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action.title,
              style: styles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: styles.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Color _getProjectColor(ProjectCategory category) {
    switch (category) {
      case ProjectCategory.development:
        return Colors.blue;
      case ProjectCategory.design:
        return Colors.purple;
      case ProjectCategory.marketing:
        return Colors.green;
      case ProjectCategory.infrastructure:
        return Colors.orange;
      case ProjectCategory.research:
        return Colors.teal;
    }
  }

  IconData _getProjectIcon(ProjectCategory category) {
    switch (category) {
      case ProjectCategory.development:
        return Icons.code;
      case ProjectCategory.design:
        return Icons.palette;
      case ProjectCategory.marketing:
        return Icons.campaign;
      case ProjectCategory.infrastructure:
        return Icons.cloud;
      case ProjectCategory.research:
        return Icons.science;
    }
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return Colors.blue;
      case ProjectStatus.active:
        return Colors.green;
      case ProjectStatus.paused:
        return Colors.orange;
      case ProjectStatus.completed:
        return Colors.teal;
      case ProjectStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.paused:
        return 'Paused';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _showCreateProjectDialog() {
    _showComingSoonSnackBar();
  }

  void _showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon! This feature is in development.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

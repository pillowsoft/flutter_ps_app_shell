import 'dart:math';
import 'dart:math' as math;

/// Realistic sample data models and generators for the example app
class SampleData {
  static final _random = Random();

  // Sample users for demonstration
  static List<UserProfile> get sampleUsers => [
        UserProfile(
          id: '1',
          name: 'Sarah Johnson',
          email: 'sarah.johnson@example.com',
          avatar: '👩‍💼',
          role: 'Product Manager',
          department: 'Product',
          joinDate: DateTime.now().subtract(const Duration(days: 365)),
          isActive: true,
          projects: ['Mobile App', 'Web Platform'],
        ),
        UserProfile(
          id: '2',
          name: 'Alex Chen',
          email: 'alex.chen@example.com',
          avatar: '👨‍💻',
          role: 'Senior Developer',
          department: 'Engineering',
          joinDate: DateTime.now().subtract(const Duration(days: 180)),
          isActive: true,
          projects: ['API Gateway', 'Mobile App'],
        ),
        UserProfile(
          id: '3',
          name: 'Maria Rodriguez',
          email: 'maria.rodriguez@example.com',
          avatar: '👩‍🎨',
          role: 'UX Designer',
          department: 'Design',
          joinDate: DateTime.now().subtract(const Duration(days: 90)),
          isActive: true,
          projects: ['Design System', 'Mobile App'],
        ),
        UserProfile(
          id: '4',
          name: 'James Wilson',
          email: 'james.wilson@example.com',
          avatar: '👨‍💼',
          role: 'Sales Director',
          department: 'Sales',
          joinDate: DateTime.now().subtract(const Duration(days: 500)),
          isActive: false,
          projects: ['Customer Onboarding'],
        ),
      ];

  // Sample projects
  static List<Project> get sampleProjects => [
        Project(
          id: '1',
          name: 'Mobile App',
          description: 'Cross-platform mobile application using Flutter',
          status: ProjectStatus.active,
          progress: 0.75,
          startDate: DateTime.now().subtract(const Duration(days: 120)),
          endDate: DateTime.now().add(const Duration(days: 30)),
          teamSize: 8,
          budget: 150000,
          category: ProjectCategory.development,
        ),
        Project(
          id: '2',
          name: 'Web Platform',
          description: 'Modernization of legacy web platform',
          status: ProjectStatus.planning,
          progress: 0.15,
          startDate: DateTime.now().add(const Duration(days: 14)),
          endDate: DateTime.now().add(const Duration(days: 180)),
          teamSize: 12,
          budget: 300000,
          category: ProjectCategory.development,
        ),
        Project(
          id: '3',
          name: 'Design System',
          description: 'Comprehensive design system and component library',
          status: ProjectStatus.active,
          progress: 0.60,
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          endDate: DateTime.now().add(const Duration(days: 60)),
          teamSize: 4,
          budget: 75000,
          category: ProjectCategory.design,
        ),
        Project(
          id: '4',
          name: 'API Gateway',
          description: 'Microservices API gateway and authentication layer',
          status: ProjectStatus.completed,
          progress: 1.0,
          startDate: DateTime.now().subtract(const Duration(days: 200)),
          endDate: DateTime.now().subtract(const Duration(days: 30)),
          teamSize: 6,
          budget: 120000,
          category: ProjectCategory.infrastructure,
        ),
      ];

  // Generate realistic metrics data
  static DashboardMetrics generateMetrics() {
    final now = DateTime.now();
    final activeUsers = 1200 + _random.nextInt(300);
    final revenue = 45000 + _random.nextDouble() * 15000;
    final growth = 0.15 + _random.nextDouble() * 0.20;
    final performance = 0.95 + _random.nextDouble() * 0.05;

    return DashboardMetrics(
      activeUsers: activeUsers,
      revenue: revenue,
      growth: growth,
      performance: performance,
      lastUpdated: now,
      userGrowthData: _generateUserGrowthData(),
      revenueData: _generateRevenueData(),
    );
  }

  static List<DataPoint> _generateUserGrowthData() {
    final data = <DataPoint>[];
    final now = DateTime.now();

    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final baseValue = 1000;
      final variation = _random.nextInt(200) - 100;
      data.add(DataPoint(
        date: date,
        value: baseValue + variation + (30 - i) * 10,
      ));
    }

    return data;
  }

  static List<DataPoint> _generateRevenueData() {
    final data = <DataPoint>[];
    final now = DateTime.now();

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final baseValue = 40000.0;
      final seasonality = math.sin(i * math.pi / 6) * 5000;
      final growth = i * 500;
      final noise = (_random.nextDouble() - 0.5) * 3000;

      data.add(DataPoint(
        date: date,
        value: baseValue + seasonality + growth + noise,
      ));
    }

    return data;
  }

  // Sample tasks for project management
  static List<Task> generateSampleTasks() => [
        Task(
          id: '1',
          title: 'Implement user authentication',
          description:
              'Add secure login and signup functionality with JWT tokens',
          status: TaskStatus.completed,
          priority: TaskPriority.high,
          assigneeId: '2',
          projectId: '1',
          createdDate: DateTime.now().subtract(const Duration(days: 10)),
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          tags: ['backend', 'security'],
        ),
        Task(
          id: '2',
          title: 'Design onboarding flow',
          description:
              'Create intuitive user onboarding experience with progressive disclosure',
          status: TaskStatus.inProgress,
          priority: TaskPriority.high,
          assigneeId: '3',
          projectId: '1',
          createdDate: DateTime.now().subtract(const Duration(days: 5)),
          dueDate: DateTime.now().add(const Duration(days: 3)),
          tags: ['design', 'ux'],
        ),
        Task(
          id: '3',
          title: 'Optimize database queries',
          description: 'Improve performance of user dashboard loading times',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
          assigneeId: '2',
          projectId: '1',
          createdDate: DateTime.now().subtract(const Duration(days: 1)),
          dueDate: DateTime.now().add(const Duration(days: 7)),
          tags: ['backend', 'performance'],
        ),
        Task(
          id: '4',
          title: 'Set up CI/CD pipeline',
          description:
              'Automated testing and deployment pipeline for mobile app',
          status: TaskStatus.inProgress,
          priority: TaskPriority.medium,
          assigneeId: '2',
          projectId: '1',
          createdDate: DateTime.now().subtract(const Duration(days: 3)),
          dueDate: DateTime.now().add(const Duration(days: 10)),
          tags: ['devops', 'automation'],
        ),
      ];
}

// Data models
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String role;
  final String department;
  final DateTime joinDate;
  final bool isActive;
  final List<String> projects;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.role,
    required this.department,
    required this.joinDate,
    required this.isActive,
    required this.projects,
  });
}

class Project {
  final String id;
  final String name;
  final String description;
  final ProjectStatus status;
  final double progress;
  final DateTime startDate;
  final DateTime endDate;
  final int teamSize;
  final double budget;
  final ProjectCategory category;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.progress,
    required this.startDate,
    required this.endDate,
    required this.teamSize,
    required this.budget,
    required this.category,
  });
}

enum ProjectStatus { planning, active, paused, completed, cancelled }

enum ProjectCategory {
  development,
  design,
  marketing,
  infrastructure,
  research
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String assigneeId;
  final String projectId;
  final DateTime createdDate;
  final DateTime dueDate;
  final List<String> tags;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assigneeId,
    required this.projectId,
    required this.createdDate,
    required this.dueDate,
    required this.tags,
  });
}

enum TaskStatus { todo, inProgress, review, completed }

enum TaskPriority { low, medium, high, urgent }

class DashboardMetrics {
  final int activeUsers;
  final double revenue;
  final double growth;
  final double performance;
  final DateTime lastUpdated;
  final List<DataPoint> userGrowthData;
  final List<DataPoint> revenueData;

  const DashboardMetrics({
    required this.activeUsers,
    required this.revenue,
    required this.growth,
    required this.performance,
    required this.lastUpdated,
    required this.userGrowthData,
    required this.revenueData,
  });
}

class DataPoint {
  final DateTime date;
  final double value;

  const DataPoint({
    required this.date,
    required this.value,
  });
}

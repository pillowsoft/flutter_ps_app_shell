import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_vizi_camera_app/core/di/service_locator.dart';
import 'package:flutter_vizi_camera_app/services/settings_service.dart';
import 'package:flutter_vizi_camera_app/services/auth_service.dart';
import 'package:flutter_vizi_camera_app/services/wizard_state_service.dart';
import 'package:flutter_vizi_camera_app/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_vizi_camera_app/screens/auth/auth_screen.dart';
import 'package:flutter_vizi_camera_app/screens/auth/email_auth_screen.dart';
import 'package:flutter_vizi_camera_app/screens/home/main_tab_screen_adaptive.dart';
import 'package:flutter_vizi_camera_app/screens/home/guided_mode_home_screen.dart';
import 'package:flutter_vizi_camera_app/screens/projects/projects_screen_adaptive.dart';
import 'package:flutter_vizi_camera_app/screens/projects/project_detail_screen.dart';
import 'package:flutter_vizi_camera_app/screens/projects/new_project_screen_adaptive.dart';
import 'package:flutter_vizi_camera_app/screens/camera/recording_screen.dart';
import 'package:flutter_vizi_camera_app/screens/camera/collaborate_screen.dart';
import 'package:flutter_vizi_camera_app/screens/camera/qr_code_screen.dart';
import 'package:flutter_vizi_camera_app/screens/camera/participants_screen.dart';
import 'package:flutter_vizi_camera_app/screens/video_player_screen.dart';
import 'package:flutter_vizi_camera_app/screens/settings_screen_adaptive.dart';
import 'package:flutter_vizi_camera_app/screens/settings/camera_settings_screen.dart';
import 'package:flutter_vizi_camera_app/screens/settings/recording_settings_screen.dart';
import 'package:flutter_vizi_camera_app/screens/settings/privacy_settings_screen.dart';
import 'package:flutter_vizi_camera_app/screens/settings/wizard_settings_screen.dart';
import 'package:flutter_vizi_camera_app/screens/debug/collaborative_test_screen.dart';
import 'package:flutter_vizi_camera_app/shells/guided_mode_shell.dart';
// Wizard screens
import 'package:flutter_vizi_camera_app/screens/wizard/wizard_start_screen.dart';
import 'package:flutter_vizi_camera_app/screens/wizard/wizard_project_details_screen.dart';
import 'package:flutter_vizi_camera_app/screens/wizard/wizard_invite_screen.dart';

// Use static keys to prevent recreation
class _NavigatorKeys {
  static final GlobalKey<NavigatorState> root =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> shell =
      GlobalKey<NavigatorState>(debugLabel: 'shell');
}

final appRouter = GoRouter(
  navigatorKey: _NavigatorKeys.root,
  initialLocation: '/',
  redirect: (context, state) {
    final settingsService = getIt<SettingsService>();
    final authService = getIt<AuthService>();
    final isOnboarded = settingsService.hasCompletedOnboarding.value;
    final isAuthenticated = authService.isAuthenticated;

    // Skip redirect for tab navigation between projects and settings
    final isTabNavigation = (state.uri.path == '/projects' ||
            state.uri.path == '/settings' ||
            state.uri.path == '/guided-home') &&
        isOnboarded &&
        isAuthenticated;

    if (isTabNavigation) {
      return null; // No redirect needed for tab switches
    }

    // Debug: print navigation info only for non-tab navigation
    debugPrint(
        'Navigation redirect: path=${state.uri.path}, isOnboarded=$isOnboarded, isAuthenticated=$isAuthenticated');

    // If not onboarded, redirect to onboarding
    if (!isOnboarded && state.uri.path != '/onboarding') {
      debugPrint('Redirecting to onboarding');
      return '/onboarding';
    }

    // If onboarded but not authenticated, allow auth routes but redirect others to auth
    if (isOnboarded &&
        !isAuthenticated &&
        !state.uri.path.startsWith('/auth')) {
      debugPrint('Redirecting to auth');
      return '/auth';
    }

    // If authenticated and onboarded, redirect from auth screen to projects
    if (isAuthenticated && isOnboarded && state.uri.path.startsWith('/auth')) {
      debugPrint('Redirecting to projects');
      return '/projects';
    }

    // If we're at the root, redirect based on auth state and guided mode
    if (state.uri.path == '/') {
      if (!isOnboarded) {
        return '/onboarding';
      } else if (!isAuthenticated) {
        return '/auth';
      } else {
        // Check if guided mode is enabled
        return settingsService.guidedModeEnabled.value
            ? '/guided-home'
            : '/projects';
      }
    }

    return null;
  },
  routes: [
    // Onboarding route
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Authentication routes
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
      routes: [
        GoRoute(
          path: 'email',
          builder: (context, state) =>
              const EmailAuthScreen(isMagicLink: false),
        ),
        GoRoute(
          path: 'magic-link',
          builder: (context, state) => const EmailAuthScreen(isMagicLink: true),
        ),
      ],
    ),

    // Main app with bottom navigation using ShellRoute
    ShellRoute(
      navigatorKey: _NavigatorKeys.shell,
      builder: (context, state, child) {
        final settingsService = getIt<SettingsService>();
        final wizardService = getIt<WizardStateService>();

        // If wizard is active, just return the child (wizard screens handle their own UI)
        if (wizardService.isActive.value) {
          return child;
        }

        // Otherwise, use appropriate shell based on guided mode
        return settingsService.guidedModeEnabled.value
            ? GuidedModeShell(child: child)
            : MainTabScreenAdaptive(child: child);
      },
      routes: [
        // Projects routes
        GoRoute(
          path: '/projects',
          pageBuilder: (context, state) {
            final settingsService = getIt<SettingsService>();
            final wizardService = getIt<WizardStateService>();

            // In guided mode, redirect to settings unless wizard is active
            if (settingsService.guidedModeEnabled.value &&
                !wizardService.isActive.value) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const SizedBox.shrink(),
              );
            }

            return NoTransitionPage(
              key: state.pageKey,
              child: const ProjectsScreenAdaptive(),
            );
          },
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const NewProjectScreenAdaptive(),
            ),
            GoRoute(
              path: ':projectId',
              builder: (context, state) {
                final projectId = state.pathParameters['projectId']!;
                return ProjectDetailScreen(projectId: projectId);
              },
              routes: [
                GoRoute(
                  path: 'recording',
                  builder: (context, state) {
                    final projectId = state.pathParameters['projectId']!;
                    return RecordingScreen(projectId: projectId);
                  },
                ),
                GoRoute(
                  path: 'collaborate',
                  builder: (context, state) => const CollaborateScreen(),
                ),
                GoRoute(
                  path: 'qr-code',
                  builder: (context, state) => const QRCodeScreen(),
                ),
                GoRoute(
                  path: 'participants',
                  builder: (context, state) => const ParticipantsScreen(),
                ),
                GoRoute(
                  path: 'video/:videoPath',
                  builder: (context, state) {
                    final videoPath = state.pathParameters['videoPath']!;
                    return VideoPlayerScreen(videoPath: videoPath);
                  },
                ),
              ],
            ),
          ],
        ),

        // Guided mode home route
        GoRoute(
          path: '/guided-home',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const GuidedModeHomeScreen(),
          ),
        ),

        // Settings route
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SettingsScreenAdaptive(),
          ),
          routes: [
            GoRoute(
              path: 'camera',
              builder: (context, state) => const CameraSettingsScreen(),
            ),
            GoRoute(
              path: 'recording',
              builder: (context, state) => const RecordingSettingsScreen(),
            ),
            GoRoute(
              path: 'privacy',
              builder: (context, state) => const PrivacySettingsScreen(),
            ),
            GoRoute(
              path: 'wizard',
              builder: (context, state) => const WizardSettingsScreen(),
            ),
            GoRoute(
              path: 'debug/collaborative-test',
              builder: (context, state) => const CollaborativeTestScreen(),
            ),
          ],
        ),

        // Wizard routes
        GoRoute(
          path: '/wizard/start',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const WizardStartScreen(),
          ),
        ),
        GoRoute(
          path: '/wizard/project-details',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const WizardProjectDetailsScreen(),
          ),
        ),
        GoRoute(
          path: '/wizard/invite',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const WizardInviteScreen(),
          ),
        ),
        GoRoute(
          path: '/wizard/camera-preview',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const Center(child: Text('Camera Preview - Coming Soon')),
          ),
        ),
        GoRoute(
          path: '/wizard/recording',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const Center(child: Text('Recording - Coming Soon')),
          ),
        ),
        GoRoute(
          path: '/wizard/processing',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const Center(child: Text('Processing - Coming Soon')),
          ),
        ),
        GoRoute(
          path: '/wizard/edl-preview',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const Center(child: Text('EDL Preview - Coming Soon')),
          ),
        ),
        GoRoute(
          path: '/wizard/share',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const Center(child: Text('Share - Coming Soon')),
          ),
        ),
      ],
    ),

    // Session join route (outside of shell)
    GoRoute(
      path: '/join/:inviteCode',
      builder: (context, state) {
        final inviteCode = state.pathParameters['inviteCode']!;
        return JoinSessionScreen(inviteCode: inviteCode);
      },
    ),
  ],
);

// Navigation helper functions
class AppNavigation {
  static void goToProjects() {
    appRouter.go('/projects');
  }

  static void goToSettings() {
    appRouter.go('/settings');
  }

  static void goToCameraSettings() {
    appRouter.go('/settings/camera');
  }

  static void goToRecordingSettings() {
    appRouter.go('/settings/recording');
  }

  static void goToPrivacySettings() {
    appRouter.go('/settings/privacy');
  }

  static void goToNewProject() {
    appRouter.go('/projects/new');
  }

  static void goToProjectDetail(String projectId) {
    appRouter.go('/projects/$projectId');
  }

  static void goToRecording({required String projectId}) {
    appRouter.go('/projects/$projectId/recording');
  }

  static void goToCollaborate(String projectId) {
    appRouter.go('/projects/$projectId/collaborate');
  }

  static void goToQRCode(String projectId) {
    appRouter.go('/projects/$projectId/qr-code');
  }

  static void goToParticipants(String projectId) {
    appRouter.go('/projects/$projectId/participants');
  }

  static void goToVideoPlayer(String projectId, String videoPath) {
    appRouter.go('/projects/$projectId/video/$videoPath');
  }

  static void goToJoinSession(String inviteCode) {
    appRouter.go('/join/$inviteCode');
  }

  static void goBack() {
    appRouter.pop();
  }

  static bool canPop() {
    return appRouter.canPop();
  }
}

// Placeholder screen for join session
class JoinSessionScreen extends StatelessWidget {
  final String inviteCode;

  const JoinSessionScreen({super.key, required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Session')),
      body: Center(
        child: Text('Joining session with code: $inviteCode'),
      ),
    );
  }
}

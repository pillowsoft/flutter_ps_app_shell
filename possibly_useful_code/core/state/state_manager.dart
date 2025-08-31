import 'package:flutter_vizi_camera_app/core/state/app_state.dart';
import 'package:flutter_vizi_camera_app/core/di/service_locator.dart';
import 'package:flutter_vizi_camera_app/managers/settings_manager.dart';
import 'package:flutter_vizi_camera_app/managers/project_manager.dart';
import 'package:flutter_vizi_camera_app/repositories/user_repository.dart';

class StateManager {
  static final StateManager _instance = StateManager._internal();
  factory StateManager() => _instance;
  StateManager._internal();

  bool _isInitialized = false;

  // Services
  late final SettingsManager _settingsManager;
  late final ProjectManager _projectManager;
  late final UserRepository _userRepository;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Get services from service locator
    _settingsManager = getIt<SettingsManager>();
    _projectManager = getIt<ProjectManager>();
    _userRepository = getIt<UserRepository>();

    // Initialize state from persisted data
    await _loadInitialState();

    // Set up state listeners
    _setupStateListeners();

    _isInitialized = true;
  }

  Future<void> _loadInitialState() async {
    // Load settings
    final settings = _settingsManager.settings.value;

    // Load current user
    final currentUser = await _userRepository.getCurrentUser();

    // Initialize and load projects
    await _projectManager.initialize();
    final projects = _projectManager.projects.value;

    // Update app state
    updateAppState(AppState(
      isOnboarded: settings['onboarded'] ?? false,
      currentUser: currentUser,
      activeSessionId: null,
      isOffline: false,
      settings: settings,
    ));

    updateProjectsState(projects);
  }

  void _setupStateListeners() {
    // Listen to settings changes without creating circular dependency
    _settingsManager.settings.subscribe((settings) {
      final current = appState.peek(); // Use peek to avoid tracking
      if (current.settings != settings) {
        updateAppState(current.copyWith(settings: settings));
      }
    });

    // Listen to project changes
    _projectManager.projects.subscribe((projects) {
      if (projectsState.peek() != projects) {
        updateProjectsState(projects);
      }
    });

    // Listen to current project changes
    _projectManager.currentProject.subscribe((currentProject) {
      if (currentProjectState.peek() != currentProject) {
        updateCurrentProject(currentProject);
      }
    });
  }

  void dispose() {
    // Clean up any subscriptions or resources
    _isInitialized = false;
  }

  // Helper methods for common state operations
  Future<void> login(User user) async {
    final current = appState.value;
    updateAppState(current.copyWith(currentUser: user));
  }

  Future<void> logout() async {
    final current = appState.value;
    updateAppState(current.copyWith(currentUser: null));

    // Clear session state
    updateSessionState(null);

    // Reset collaboration state
    updateCollaborationState(CollaborationState.disconnected());
  }

  Future<void> completeOnboarding() async {
    await _settingsManager.updateSetting('onboarded', true);

    final current = appState.value;
    updateAppState(current.copyWith(isOnboarded: true));
  }

  Future<void> setOfflineMode(bool isOffline) async {
    final current = appState.value;
    updateAppState(current.copyWith(isOffline: isOffline));
  }

  Future<void> joinSession(
      String sessionId, String sessionName, String role) async {
    final sessionState = SessionState(
      sessionId: sessionId,
      sessionName: sessionName,
      role: role,
      participants: [],
      status: SessionStatus.waiting,
      settings: {},
    );

    updateSessionState(sessionState);

    final current = appState.value;
    updateAppState(current.copyWith(activeSessionId: sessionId));
  }

  Future<void> leaveSession() async {
    updateSessionState(null);
    updateCollaborationState(CollaborationState.disconnected());

    final current = appState.value;
    updateAppState(current.copyWith(activeSessionId: null));
  }
}

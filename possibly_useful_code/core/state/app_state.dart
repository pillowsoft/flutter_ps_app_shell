import 'package:signals/signals.dart';
import 'package:flutter_vizi_camera_app/repositories/user_repository.dart';
import 'package:flutter_vizi_camera_app/managers/project_manager.dart' as pm;
import 'package:flutter_vizi_camera_app/models/participant.dart';
import 'package:flutter_vizi_camera_app/models/project.dart';
import 'package:flutter_vizi_camera_app/models/user_profile.dart';

// Global app state signals
final appState = signal<AppState>(AppState.initial());
final recordingState = signal<RecordingState>(RecordingState.idle());
final sessionState = signal<SessionState?>(null);
final projectsState = signal<List<Project>>([]);
final currentProjectState = signal<Project?>(null);
final collaborationState =
    signal<CollaborationState>(CollaborationState.disconnected());

// Recording state management
class RecordingState {
  final bool isRecording;
  final bool isPaused;
  final Duration duration;
  final double quality;
  final List<String> feedback;

  const RecordingState({
    required this.isRecording,
    required this.isPaused,
    required this.duration,
    required this.quality,
    required this.feedback,
  });

  static RecordingState idle() => const RecordingState(
        isRecording: false,
        isPaused: false,
        duration: Duration.zero,
        quality: 0.0,
        feedback: [],
      );

  RecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    Duration? duration,
    double? quality,
    List<String>? feedback,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      duration: duration ?? this.duration,
      quality: quality ?? this.quality,
      feedback: feedback ?? this.feedback,
    );
  }
}

// Main app state
class AppState {
  final bool isOnboarded;
  final User? currentUser;
  final String? activeSessionId;
  final bool isOffline;
  final Map<String, dynamic> settings;

  const AppState({
    required this.isOnboarded,
    this.currentUser,
    this.activeSessionId,
    required this.isOffline,
    required this.settings,
  });

  static AppState initial() => const AppState(
        isOnboarded: false,
        isOffline: false,
        settings: {},
      );

  AppState copyWith({
    bool? isOnboarded,
    User? currentUser,
    String? activeSessionId,
    bool? isOffline,
    Map<String, dynamic>? settings,
  }) {
    return AppState(
      isOnboarded: isOnboarded ?? this.isOnboarded,
      currentUser: currentUser ?? this.currentUser,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isOffline: isOffline ?? this.isOffline,
      settings: settings ?? this.settings,
    );
  }
}

// Session state for collaboration
class SessionState {
  final String sessionId;
  final String sessionName;
  final String role; // 'master' or 'participant'
  final List<Participant> participants;
  final SessionStatus status;
  final Map<String, dynamic> settings;

  const SessionState({
    required this.sessionId,
    required this.sessionName,
    required this.role,
    required this.participants,
    required this.status,
    required this.settings,
  });

  SessionState copyWith({
    String? sessionId,
    String? sessionName,
    String? role,
    List<Participant>? participants,
    SessionStatus? status,
    Map<String, dynamic>? settings,
  }) {
    return SessionState(
      sessionId: sessionId ?? this.sessionId,
      sessionName: sessionName ?? this.sessionName,
      role: role ?? this.role,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      settings: settings ?? this.settings,
    );
  }
}

// Collaboration state
class CollaborationState {
  final bool isConnected;
  final int participantCount;
  final List<String> connectedDevices;
  final Map<String, dynamic> syncStatus;

  const CollaborationState({
    required this.isConnected,
    required this.participantCount,
    required this.connectedDevices,
    required this.syncStatus,
  });

  static CollaborationState disconnected() => const CollaborationState(
        isConnected: false,
        participantCount: 0,
        connectedDevices: [],
        syncStatus: {},
      );

  CollaborationState copyWith({
    bool? isConnected,
    int? participantCount,
    List<String>? connectedDevices,
    Map<String, dynamic>? syncStatus,
  }) {
    return CollaborationState(
      isConnected: isConnected ?? this.isConnected,
      participantCount: participantCount ?? this.participantCount,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

enum SessionStatus {
  waiting,
  setup,
  recording,
  paused,
  completed,
  error,
}

// State update functions
void updateAppState(AppState newState) {
  appState.value = newState;
}

void updateRecordingState(RecordingState newState) {
  recordingState.value = newState;
}

void updateSessionState(SessionState? newState) {
  sessionState.value = newState;
}

void updateProjectsState(List<Project> projects) {
  projectsState.value = projects;
}

void updateCurrentProject(Project? project) {
  currentProjectState.value = project;
}

void updateCollaborationState(CollaborationState newState) {
  collaborationState.value = newState;
}

// Helper functions for common state updates
void startRecording() {
  final current = recordingState.value;
  updateRecordingState(current.copyWith(isRecording: true));
}

void stopRecording() {
  final current = recordingState.value;
  updateRecordingState(current.copyWith(
    isRecording: false,
    isPaused: false,
    duration: Duration.zero,
  ));
}

void pauseRecording() {
  final current = recordingState.value;
  updateRecordingState(current.copyWith(isPaused: true));
}

void resumeRecording() {
  final current = recordingState.value;
  updateRecordingState(current.copyWith(isPaused: false));
}

void updateRecordingQuality(double quality) {
  final current = recordingState.value;
  updateRecordingState(current.copyWith(quality: quality));
}

void addRecordingFeedback(String message) {
  final current = recordingState.value;
  final feedback = [...current.feedback, message];
  updateRecordingState(current.copyWith(feedback: feedback));
}

void clearRecordingFeedback() {
  final current = recordingState.value;
  updateRecordingState(current.copyWith(feedback: []));
}

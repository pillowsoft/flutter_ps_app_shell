// LEGACY CODE - DEPRECATED
// This file contains prototype code from before the InstantDB migration.
// References to SupabaseService and ReaxDBService are legacy - current
// implementation uses InstantDB for database and authentication.
// See packages/flutter_app_shell/ for current implementation.

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_vizi_camera_app/services/camera/camera_interface.dart';
import 'package:flutter_vizi_camera_app/services/camera/camera_factory.dart';
import 'package:flutter_vizi_camera_app/services/audio_service.dart';
import 'package:flutter_vizi_camera_app/services/sensor_service.dart';
import 'package:flutter_vizi_camera_app/services/realtime_service.dart';
import 'package:flutter_vizi_camera_app/services/auth_service.dart';
import 'package:flutter_vizi_camera_app/services/supabase_service.dart';
import 'package:flutter_vizi_camera_app/services/ai_processing_service.dart';
import 'package:flutter_vizi_camera_app/services/storage_service.dart';
import 'package:flutter_vizi_camera_app/services/permission_service.dart';
import 'package:flutter_vizi_camera_app/services/notification_service.dart';
import 'package:flutter_vizi_camera_app/services/reaxdb_service.dart';
import 'package:flutter_vizi_camera_app/services/quality_feedback_service.dart';
import 'package:flutter_vizi_camera_app/services/qr_code_service.dart';
import 'package:flutter_vizi_camera_app/services/scene_analysis_service.dart';
import 'package:flutter_vizi_camera_app/services/sensor_fusion_service.dart';
import 'package:flutter_vizi_camera_app/services/job_monitor_service.dart';
import 'package:flutter_vizi_camera_app/services/settings_service.dart';
import 'package:flutter_vizi_camera_app/services/social_sharing_service.dart';
import 'package:flutter_vizi_camera_app/services/gopro_service.dart';
import 'package:flutter_vizi_camera_app/services/cloud_storage_service.dart';
import 'package:flutter_vizi_camera_app/services/video_optimization_service.dart';
import 'package:flutter_vizi_camera_app/services/sharing_analytics_service.dart';
import 'package:flutter_vizi_camera_app/services/video_filter_service.dart';
import 'package:flutter_vizi_camera_app/services/advanced_camera_service.dart';
import 'package:flutter_vizi_camera_app/managers/session_manager.dart';
import 'package:flutter_vizi_camera_app/managers/metadata_manager.dart';
import 'package:flutter_vizi_camera_app/managers/upload_manager.dart';
import 'package:flutter_vizi_camera_app/managers/quality_feedback_manager.dart';
import 'package:flutter_vizi_camera_app/managers/settings_manager.dart';
import 'package:flutter_vizi_camera_app/managers/project_manager.dart';
import 'package:flutter_vizi_camera_app/ui/adaptive/adaptive_widgets.dart';
import 'package:flutter_vizi_camera_app/repositories/project_repository.dart';
import 'package:flutter_vizi_camera_app/repositories/video_repository.dart';
import 'package:flutter_vizi_camera_app/repositories/user_repository.dart';
import 'package:flutter_vizi_camera_app/services/document_db_service.dart';
import 'package:flutter_vizi_camera_app/services/supabase_document_db.dart';
import 'package:flutter_vizi_camera_app/services/wizard_state_service.dart';
import 'package:flutter_vizi_camera_app/services/livekit_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Log platform information for camera setup
  CameraServiceFactory.logPlatformInfo();

  // Services - Lazy singletons
  getIt.registerLazySingleton<ICameraService>(() {
    debugPrint('🎥🎥🎥 SERVICE LOCATOR: About to create camera service...');
    final cameraService = CameraServiceFactory.create();
    debugPrint(
        '🎥🎥🎥 SERVICE LOCATOR: Created camera service: ${cameraService.runtimeType}');
    debugPrint(
        '🎥🎥🎥 SERVICE LOCATOR: Is desktop impl: ${cameraService.runtimeType.toString().contains('Desktop')}');
    return cameraService;
  });
  getIt.registerLazySingleton<AudioService>(() => AudioService());
  getIt.registerLazySingleton<SensorService>(() => SensorService());
  getIt.registerLazySingleton<RealtimeService>(() => RealtimeService.instance);
  getIt.registerLazySingleton<AIProcessingService>(() => AIProcessingService());
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<PermissionService>(() => PermissionService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<QualityFeedbackService>(
      () => QualityFeedbackService());
  getIt.registerLazySingleton<QRCodeService>(() => QRCodeService.instance);
  getIt.registerLazySingleton<SceneAnalysisService>(
      () => SceneAnalysisService());
  getIt.registerLazySingleton<SensorFusionService>(() => SensorFusionService());
  getIt.registerLazySingleton<JobMonitorService>(() => JobMonitorService());
  getIt.registerLazySingleton<SettingsService>(() => SettingsService());
  getIt.registerLazySingleton<SocialSharingService>(
      () => SocialSharingService());
  getIt.registerLazySingleton<GoProService>(() => GoProService());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<CloudStorageService>(() => CloudStorageService());
  getIt.registerLazySingleton<SupabaseService>(() => SupabaseService.instance);
  getIt.registerLazySingleton<DocumentDbService>(() {
    final supabaseService = getIt<SupabaseService>();
    if (supabaseService.client == null) {
      throw Exception('Supabase client not initialized');
    }
    return SupabaseDocumentDb(supabaseService.client!);
  });
  getIt.registerLazySingleton<VideoOptimizationService>(
      () => VideoOptimizationService());
  getIt.registerLazySingleton<SharingAnalyticsService>(
      () => SharingAnalyticsService());
  getIt.registerLazySingleton<VideoFilterService>(() => VideoFilterService());
  getIt.registerLazySingleton<AdvancedCameraService>(
      () => AdvancedCameraService());
  getIt.registerLazySingleton<WizardStateService>(
      () => WizardStateService.instance);
  getIt.registerLazySingleton<LiveKitService>(() => LiveKitService.instance);

  // Managers - Lazy singletons
  getIt.registerLazySingleton<SessionManager>(() => SessionManager());
  getIt.registerLazySingleton<MetadataManager>(() => MetadataManager());
  getIt.registerLazySingleton<UploadManager>(() => UploadManager());
  getIt.registerLazySingleton<QualityFeedbackManager>(
      () => QualityFeedbackManager());
  getIt.registerLazySingleton<SettingsManager>(() => SettingsManager());
  getIt.registerLazySingleton<ProjectManager>(() => ProjectManager());

  // Repositories - Lazy singletons
  getIt.registerLazySingleton<ProjectRepository>(() => ProjectRepository());
  getIt.registerLazySingleton<VideoRepository>(() => VideoRepository());
  getIt.registerLazySingleton<UserRepository>(() => UserRepository());

  // Setup adaptive UI factory
  setupAdaptiveUI();

  // Initialize critical services
  await _initializeCriticalServices();
}

Future<void> _initializeCriticalServices() async {
  // Initialize both databases during migration period
  await ReaxDBService.initializeReaxDB();
  // HiveService removed - using ReaxDB now

  // Initialize settings service first as other services depend on it
  await getIt<SettingsService>().initialize();

  // Initialize settings manager first as other services depend on it
  await getIt<SettingsManager>().initialize();

  // Initialize permission service
  try {
    await getIt<PermissionService>().initialize();
  } catch (e) {
    debugPrint(
        'Warning: Permission service initialization failed on this platform: $e');
    // Continue without failing - permissions will be handled differently on macOS
  }

  // Initialize storage service
  await getIt<StorageService>().initialize();

  // Initialize quality feedback service
  await getIt<QualityFeedbackService>().initialize();

  // Initialize sensor service
  await getIt<SensorService>().initialize();

  // Initialize audio service
  await getIt<AudioService>().initialize();

  // Initialize scene analysis service
  await getIt<SceneAnalysisService>().initialize();

  // Initialize sensor fusion service
  await getIt<SensorFusionService>().initialize();

  // Initialize session manager
  await getIt<SessionManager>().initialize();

  // Initialize metadata manager
  await getIt<MetadataManager>().initialize();

  // Initialize upload manager
  await getIt<UploadManager>().initialize();

  // Initialize AI processing service
  await getIt<AIProcessingService>().initialize();

  // Initialize job monitor service
  await getIt<JobMonitorService>().initialize();

  // Initialize GoPro service
  await getIt<GoProService>().initialize();

  // Initialize Supabase service
  await getIt<SupabaseService>().initialize();

  // Initialize auth service
  await getIt<AuthService>().initialize();

  // Initialize realtime service
  await getIt<RealtimeService>().initialize();

  // Initialize cloud storage service
  await getIt<CloudStorageService>().initialize();

  // Initialize sharing analytics service
  await getIt<SharingAnalyticsService>().initialize();

  // Initialize video filter service
  await getIt<VideoFilterService>().initialize();

  // Initialize advanced camera service
  await getIt<AdvancedCameraService>().initialize();
}

// Helper function to reset services (useful for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}

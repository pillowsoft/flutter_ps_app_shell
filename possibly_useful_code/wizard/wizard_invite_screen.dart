import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:livekit_client/livekit_client.dart' show ConnectionQuality;
import '../../ui/adaptive/adaptive_widgets.dart';
import '../../core/di/service_locator.dart';
import '../../services/wizard_state_service.dart';
import '../../services/qr_code_service.dart';
import '../../services/realtime_service.dart';
import '../../services/livekit_service.dart';
import '../../managers/session_manager.dart';
import '../../widgets/wizard/wizard_navigation_bar.dart';
import '../../config/livekit_config.dart';

class WizardInviteScreen extends StatefulWidget {
  const WizardInviteScreen({super.key});

  @override
  State<WizardInviteScreen> createState() => _WizardInviteScreenState();
}

class _WizardInviteScreenState extends State<WizardInviteScreen> {
  final _qrCodeService = QRCodeService.instance;
  String? _qrData;
  String? _shareUrl;
  bool _isCreatingProject = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeProject();
  }

  Future<void> _initializeProject() async {
    final wizardService = getIt<WizardStateService>();
    final sessionManager = getIt<SessionManager>();
    final livekitService = getIt<LiveKitService>();

    // Check if project already exists
    if (wizardService.currentProject.value != null) {
      await _setupLiveKitRoom(wizardService.currentProject.value!);
      _generateQRCode(wizardService.currentProject.value!);
      return;
    }

    setState(() {
      _isCreatingProject = true;
      _errorMessage = null;
    });

    try {
      // Create new project with wizard data
      debugPrint(
          'Creating session with title: ${wizardService.projectTitle.value}');
      debugPrint(
          'Creating session with description: ${wizardService.projectDescription.value}');

      final project = await sessionManager.createSession(
        name: wizardService.projectTitle.value.isNotEmpty
            ? wizardService.projectTitle.value
            : 'Recording ${DateTime.now().toIso8601String()}',
        description: wizardService.projectDescription.value.isNotEmpty
            ? wizardService.projectDescription.value
            : 'Video recording session',
      );

      if (project != null) {
        wizardService.setCurrentProject(project);

        // Set up LiveKit room for this project
        await _setupLiveKitRoom(project);

        _generateQRCode(project);
      } else {
        setState(() {
          _errorMessage = 'Failed to create project';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating project: $e';
      });
    } finally {
      setState(() {
        _isCreatingProject = false;
      });
    }
  }

  Future<void> _setupLiveKitRoom(dynamic project) async {
    final livekitService = getIt<LiveKitService>();

    try {
      // Connect to LiveKit room as master/producer
      final roomName = LiveKitConfig.getRoomName(project.id);
      debugPrint('Connecting to LiveKit room: $roomName');
      debugPrint('Project masterDeviceId: ${project.masterDeviceId}');

      await livekitService.connectToRoom(
        roomName: roomName,
        participantName: 'Producer',
        isMaster: true,
        deviceId: project.masterDeviceId ??
            'desktop_${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'projectId': project.id,
          'projectName': project.name ?? 'Unnamed Project',
        },
      );

      // Enable camera for preview (master can see their own camera)
      await livekitService.setCameraEnabled(true);
    } catch (e) {
      debugPrint('Error setting up LiveKit room: $e');
      // Don't fail project creation if LiveKit setup fails
      // User can still share QR code
    }
  }

  void _generateQRCode(dynamic project) {
    final realtimeService = getIt<RealtimeService>();

    // Ensure project has all required fields
    if (project.id == null || project.name == null) {
      debugPrint(
          'Error: Project missing required fields - id: ${project.id}, name: ${project.name}');
      setState(() {
        _errorMessage = 'Invalid project data';
      });
      return;
    }

    // Include LiveKit room info in QR code
    final roomName = LiveKitConfig.getRoomName(project.id);

    final qrData = _qrCodeService.generateQRCode(
      project: project,
      masterDeviceId:
          realtimeService.currentProject.value?.masterDeviceId ?? 'unknown',
      inviteCode: project.qrCode ?? _generateInviteCode(),
      metadata: {
        'app_version': '1.0.0',
        'created_at': DateTime.now().toIso8601String(),
        'livekit_room': roomName,
        'livekit_server': LiveKitConfig.serverUrl,
      },
    );

    final parsedData = _qrCodeService.parseQRCode(qrData);
    final shareUrl =
        parsedData != null ? _qrCodeService.createSessionUrl(parsedData) : null;

    if (mounted) {
      setState(() {
        _qrData = qrData;
        _shareUrl = shareUrl;
      });
    }
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final wizardService = getIt<WizardStateService>();
    final sessionManager = getIt<SessionManager>();
    final theme = Theme.of(context);

    return ui.scaffold(
      appBar: ui.appBar(
        title: const Text('Invite Collaborators'),
        leading: ui.iconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _exitWizard(context),
        ),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress indicator
                      LinearProgressIndicator(
                        value: wizardService.progress.value,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 24),

                      // Icon
                      Icon(
                        Icons.qr_code_2,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Invite Collaborators',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Share this QR code with others to join your recording project',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // QR Code or loading state
                      if (_isCreatingProject)
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_errorMessage != null)
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ui.textButton(
                                  label: 'Retry',
                                  onPressed: _initializeProject,
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_qrData != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 218.0,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: theme.colorScheme.primary,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Action buttons for QR code
                      if (_qrData != null && _shareUrl != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy Link'),
                                onPressed: () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: _shareUrl!));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Session link copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share'),
                                onPressed: () async {
                                  await Share.share(
                                    _shareUrl!,
                                    subject:
                                        'Join my ViziCam recording session',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Participants list (LiveKit)
                      Watch((context) {
                        final livekitService = getIt<LiveKitService>();
                        final remoteParticipants =
                            livekitService.participants.value;
                        final localParticipant =
                            livekitService.localParticipant.value;

                        // Total participants including local
                        final totalCount = remoteParticipants.length +
                            (localParticipant != null ? 1 : 0);

                        if (totalCount > 0) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.videocam,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Connected Cameras ($totalCount)',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Show local participant (master)
                                  if (localParticipant != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 20,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text('You (Producer)'),
                                          ),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Show remote participants (cameras)
                                  ...remoteParticipants
                                      .map((participant) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.camera_alt,
                                                  size: 20,
                                                  color: theme
                                                      .colorScheme.secondary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    participant.identity ??
                                                        'Camera',
                                                    style: theme
                                                        .textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: participant
                                                                    .connectionQuality ==
                                                                ConnectionQuality
                                                                    .excellent ||
                                                            participant
                                                                    .connectionQuality ==
                                                                ConnectionQuality
                                                                    .good
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),

                      const SizedBox(height: 24),

                      // Features list
                      _buildFeatureItem(
                        context,
                        Icons.share,
                        'Share QR Code',
                        'Send the QR code via messages or email',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.people,
                        'Track Participants',
                        'See who has joined your recording session',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.security,
                        'Secure Connection',
                        'Encrypted real-time collaboration',
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation bar
              WizardNavigationBar(
                canGoBack: true,
                canProceed: true,
                nextLabel: 'Skip',
                onBack: () {
                  wizardService.goToPreviousStep();
                  context.go('/wizard/project-details');
                },
                onNext: () {
                  wizardService.goToNextStep();
                  context.go('/wizard/camera-preview');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exitWizard(BuildContext context) {
    final wizardService = getIt<WizardStateService>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final ui = getAdaptiveFactory(dialogContext);

        return AlertDialog(
          title: const Text('Exit Wizard?'),
          content: const Text(
              'Are you sure you want to exit? Your progress will be lost.'),
          actions: [
            ui.textButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ui.textButton(
              label: 'Exit',
              onPressed: () {
                Navigator.of(dialogContext).pop();
                wizardService.exitWizard();
                context.go('/guided-home');
              },
            ),
          ],
        );
      },
    );
  }
}

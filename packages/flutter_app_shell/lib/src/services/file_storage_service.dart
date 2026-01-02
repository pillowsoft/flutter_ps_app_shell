import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:signals/signals.dart';
// Cloud storage features available through Cloudflare R2
import '../utils/logger.dart';
import 'package:logging/logging.dart';
import 'cloudflare_service.dart';

/// File storage service with local and cloud capabilities
///
/// Provides unified API for file storage with automatic fallback and synchronization
/// between local device storage and cloud storage (Cloudflare R2).
///
/// **Features:**
/// - Local file storage in application documents directory
/// - Cloud file storage via Cloudflare R2 (when enabled)
/// - Automatic cloud sync with offline-first approach
/// - Progress tracking for transfers
/// - Smart fallback (cloud → local → cloud)
/// - File metadata and listing
///
/// **Setup:**
/// ```dart
/// // Local-only mode
/// await fileStorageService.initialize();
///
/// // With cloud storage
/// await fileStorageService.initialize(
///   cloudflareService: cloudflareService,
///   defaultBucket: 'my-app-files',
/// );
/// ```
///
/// **Usage:**
/// ```dart
/// // Save file (auto-syncs to cloud if enabled)
/// final result = await fileStorageService.saveFile(
///   fileName: 'photo.jpg',
///   data: imageBytes,
///   folder: 'photos',
/// );
///
/// // Load file (tries local first, falls back to cloud)
/// final data = await fileStorageService.loadFile(
///   fileName: 'photo.jpg',
///   folder: 'photos',
/// );
///
/// // List files (merges local + cloud)
/// final files = await fileStorageService.listFiles(folder: 'photos');
/// ```
///
/// **Cloud Storage Requirements:**
/// - [CloudflareService] must be initialized and authenticated
/// - User must be signed in with InstantDB
/// - Cloudflare Workers must be deployed with R2 configured
///
/// See also: [CloudflareService] for cloud storage setup
class FileStorageService {
  static FileStorageService? _instance;
  static FileStorageService get instance =>
      _instance ??= FileStorageService._();

  FileStorageService._();

  // Service-specific logger
  static final Logger _logger = createServiceLogger('FileStorageService');

  late Directory _localStorageDir;
  String _defaultBucket = 'app-files';
  CloudflareService? _cloudflareService;

  bool get isInitialized => _localStorageDir.existsSync();

  /// Check if cloud storage is enabled and ready
  ///
  /// Cloud storage requires CloudflareService to be initialized and
  /// the user to be authenticated.
  bool get isCloudStorageEnabled =>
      _cloudflareService != null &&
      _cloudflareService!.isInitialized &&
      _cloudflareService!.currentSession != null;

  /// Signal for storage operation status
  final storageStatus = signal<StorageStatus>(StorageStatus.idle);

  /// Signal for upload/download progress
  final transferProgress = signal<double>(0.0);

  /// Signal for active transfers count
  final activeTransfers = signal<int>(0);

  /// Initialize the file storage service
  ///
  /// Optionally provide [cloudflareService] to enable cloud storage via Cloudflare R2.
  /// Set [defaultBucket] to customize the R2 bucket prefix (default: 'app-files').
  Future<void> initialize({
    String? defaultBucket,
    CloudflareService? cloudflareService,
  }) async {
    try {
      _logger.info('Initializing file storage service...');

      // Set up local storage directory
      final appDir = await getApplicationDocumentsDirectory();
      _localStorageDir = Directory(path.join(appDir.path, 'file_storage'));
      if (!_localStorageDir.existsSync()) {
        await _localStorageDir.create(recursive: true);
      }

      if (defaultBucket != null) {
        _defaultBucket = defaultBucket;
      }

      _cloudflareService = cloudflareService;

      _logger.info(
          'File storage service initialized (cloud: $isCloudStorageEnabled)');
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to initialize file storage service', e, stackTrace);
      rethrow;
    }
  }

  // File Operations

  /// Save a file to local storage and optionally sync to cloud
  ///
  /// Implements an offline-first approach: files are always saved locally first,
  /// then uploaded to cloud if enabled. If cloud upload fails, the local file
  /// remains accessible.
  ///
  /// **Parameters:**
  /// - [fileName]: Name of the file (e.g., 'photo.jpg')
  /// - [data]: File content as byte array
  /// - [folder]: Optional folder path (e.g., 'photos/vacation')
  /// - [metadata]: Optional metadata to store with cloud file
  /// - [syncToCloud]: Whether to upload to cloud (default: true)
  ///
  /// **Returns:** [FileStorageResult] with operation status and file locations
  ///
  /// **Example:**
  /// ```dart
  /// final result = await fileStorageService.saveFile(
  ///   fileName: 'photo.jpg',
  ///   data: imageBytes,
  ///   folder: 'photos',
  ///   metadata: {'description': 'Vacation photo'},
  /// );
  ///
  /// if (result.success) {
  ///   print('Local: ${result.localPath}');
  ///   print('Cloud: ${result.cloudUrl}');
  /// }
  /// ```
  Future<FileStorageResult> saveFile({
    required String fileName,
    required Uint8List data,
    String? folder,
    Map<String, String>? metadata,
    bool syncToCloud = true,
  }) async {
    _ensureInitialized();

    try {
      storageStatus.value = StorageStatus.uploading;
      activeTransfers.value++;

      // Build file path
      final filePath = _buildFilePath(fileName, folder);

      // Save locally first
      final localFile = await _saveLocalFile(filePath, data);

      String? cloudUrl;
      if (isCloudStorageEnabled && syncToCloud) {
        // Upload to cloud
        cloudUrl = await _uploadToCloud(filePath, data, metadata);
      }

      storageStatus.value = StorageStatus.idle;
      return FileStorageResult(
        success: true,
        localPath: localFile.path,
        cloudUrl: cloudUrl,
        fileName: fileName,
        size: data.length,
      );
    } catch (e, stackTrace) {
      storageStatus.value = StorageStatus.error;
      _logger.severe('Failed to save file: $fileName', e, stackTrace);
      return FileStorageResult(
        success: false,
        error: e.toString(),
        fileName: fileName,
      );
    } finally {
      activeTransfers.value--;
      transferProgress.value = 0.0;
    }
  }

  /// Load a file from local storage or cloud with smart fallback
  ///
  /// Implements intelligent fallback strategy:
  /// 1. If [preferCloud] is false (default): Try local → cloud
  /// 2. If [preferCloud] is true: Try cloud → local
  /// 3. Cloud downloads are automatically cached locally for offline access
  ///
  /// **Parameters:**
  /// - [fileName]: Name of the file to load
  /// - [folder]: Optional folder path
  /// - [preferCloud]: Prefer cloud over local (default: false)
  ///
  /// **Returns:** File content as byte array, or null if not found
  ///
  /// **Example:**
  /// ```dart
  /// // Try local first (offline-first)
  /// final data = await fileStorageService.loadFile(
  ///   fileName: 'photo.jpg',
  ///   folder: 'photos',
  /// );
  ///
  /// // Prefer cloud (always get latest version)
  /// final latestData = await fileStorageService.loadFile(
  ///   fileName: 'photo.jpg',
  ///   folder: 'photos',
  ///   preferCloud: true,
  /// );
  /// ```
  Future<Uint8List?> loadFile({
    required String fileName,
    String? folder,
    bool preferCloud = false,
  }) async {
    _ensureInitialized();

    try {
      storageStatus.value = StorageStatus.downloading;
      activeTransfers.value++;

      final filePath = _buildFilePath(fileName, folder);

      // Try local first (unless preferCloud is set)
      if (!preferCloud) {
        final localData = await _loadLocalFile(filePath);
        if (localData != null) {
          storageStatus.value = StorageStatus.idle;
          return localData;
        }
      }

      // Try cloud if available
      if (isCloudStorageEnabled) {
        final cloudData = await _downloadFromCloud(filePath);
        if (cloudData != null) {
          // Cache locally for offline access
          await _saveLocalFile(filePath, cloudData);
          storageStatus.value = StorageStatus.idle;
          return cloudData;
        }
      }

      // If preferCloud was set, try local as fallback
      if (preferCloud) {
        final localData = await _loadLocalFile(filePath);
        if (localData != null) {
          storageStatus.value = StorageStatus.idle;
          return localData;
        }
      }

      storageStatus.value = StorageStatus.idle;
      return null;
    } catch (e, stackTrace) {
      storageStatus.value = StorageStatus.error;
      _logger.severe('Failed to load file: $fileName', e, stackTrace);
      return null;
    } finally {
      activeTransfers.value--;
      transferProgress.value = 0.0;
    }
  }

  /// Delete a file from local storage and cloud
  Future<bool> deleteFile({
    required String fileName,
    String? folder,
    bool deleteFromCloud = true,
  }) async {
    _ensureInitialized();

    try {
      storageStatus.value = StorageStatus.deleting;

      final filePath = _buildFilePath(fileName, folder);
      bool localDeleted = false;
      bool cloudDeleted = false;

      // Delete from local storage
      localDeleted = await _deleteLocalFile(filePath);

      // Delete from cloud if enabled
      if (isCloudStorageEnabled && deleteFromCloud) {
        cloudDeleted = await _deleteFromCloud(filePath);
      }

      storageStatus.value = StorageStatus.idle;
      return localDeleted || cloudDeleted;
    } catch (e, stackTrace) {
      storageStatus.value = StorageStatus.error;
      _logger.severe('Failed to delete file: $fileName', e, stackTrace);
      return false;
    }
  }

  /// List files in a folder
  Future<List<FileInfo>> listFiles({
    String? folder,
    bool includeCloud = true,
  }) async {
    _ensureInitialized();

    try {
      final files = <FileInfo>[];

      // List local files
      final localFiles = await _listLocalFiles(folder);
      files.addAll(localFiles);

      // List cloud files if enabled
      if (isCloudStorageEnabled && includeCloud) {
        final cloudFiles = await _listCloudFiles(folder);

        // Merge with local files (avoid duplicates)
        for (final cloudFile in cloudFiles) {
          if (!files.any((f) => f.name == cloudFile.name)) {
            files.add(cloudFile);
          }
        }
      }

      // Sort by modification date
      files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      return files;
    } catch (e, stackTrace) {
      _logger.severe('Failed to list files', e, stackTrace);
      return [];
    }
  }

  /// Get file information
  Future<FileInfo?> getFileInfo({
    required String fileName,
    String? folder,
  }) async {
    _ensureInitialized();

    try {
      final filePath = _buildFilePath(fileName, folder);

      // Try local first
      final localInfo = await _getLocalFileInfo(filePath);
      if (localInfo != null) {
        return localInfo;
      }

      // Try cloud if available
      if (isCloudStorageEnabled) {
        return await _getCloudFileInfo(filePath);
      }

      return null;
    } catch (e, stackTrace) {
      _logger.severe('Failed to get file info: $fileName', e, stackTrace);
      return null;
    }
  }

  /// Get a public URL for a cloud file
  ///
  /// Currently returns the CDN URL or R2 key that was returned during upload.
  /// For presigned URLs with expiration, this would require additional
  /// CloudflareService support.
  Future<String?> getPublicUrl({
    required String fileName,
    String? folder,
    Duration? expiresIn,
  }) async {
    if (!isCloudStorageEnabled) return null;

    try {
      final filePath = _buildFilePath(fileName, folder);

      // TODO: Implement presigned URL generation in CloudflareService
      // For now, return the R2 key (applications can use downloadFile instead)
      final key = '$_defaultBucket/$filePath';

      _logger.warning(
          'Public URL generation not fully implemented - returning R2 key: $key');
      return key;
    } catch (e, stackTrace) {
      _logger.severe('Failed to get public URL: $fileName', e, stackTrace);
      return null;
    }
  }

  /// Sync all local files to cloud
  ///
  /// Uploads all local files to cloud storage. Useful for:
  /// - Initial cloud setup after local-only usage
  /// - Recovering from cloud failures
  /// - Manual backup operations
  ///
  /// **Parameters:**
  /// - [folder]: Sync only files in this folder (null = all files)
  ///
  /// **Returns:** [SyncResult] with upload statistics
  ///
  /// **Example:**
  /// ```dart
  /// final result = await fileStorageService.syncToCloud(folder: 'photos');
  /// print('Uploaded: ${result.filesUploaded}');
  /// print('Failed: ${result.filesFailed}');
  /// ```
  ///
  /// **Note:** Progress is tracked via [transferProgress] signal.
  Future<SyncResult> syncToCloud({String? folder}) async {
    if (!isCloudStorageEnabled) {
      return SyncResult(success: false, error: 'Cloud storage not enabled');
    }

    try {
      storageStatus.value = StorageStatus.syncing;

      final localFiles = await _listLocalFiles(folder);
      int uploaded = 0;
      int failed = 0;

      for (final file in localFiles) {
        try {
          final data = await _loadLocalFile(file.path);
          if (data != null) {
            await _uploadToCloud(file.path, data, null);
            uploaded++;
          }
        } catch (e) {
          failed++;
          _logger.warning('Failed to sync file: ${file.name}');
        }

        // Update progress
        final progress = (uploaded + failed) / localFiles.length;
        transferProgress.value = progress;
      }

      storageStatus.value = StorageStatus.idle;

      return SyncResult(
        success: true,
        filesUploaded: uploaded,
        filesFailed: failed,
      );
    } catch (e, stackTrace) {
      storageStatus.value = StorageStatus.error;
      _logger.severe('Failed to sync to cloud', e, stackTrace);
      return SyncResult(success: false, error: e.toString());
    } finally {
      transferProgress.value = 0.0;
    }
  }

  /// Sync all cloud files to local storage
  ///
  /// Downloads all cloud files to local device. Useful for:
  /// - Initial device setup (download user's files)
  /// - Offline mode preparation
  /// - Multi-device synchronization
  ///
  /// **Parameters:**
  /// - [folder]: Sync only files in this folder (null = all files)
  ///
  /// **Returns:** [SyncResult] with download statistics
  ///
  /// **Example:**
  /// ```dart
  /// // Download all files for offline access
  /// final result = await fileStorageService.syncFromCloud();
  /// print('Downloaded: ${result.filesDownloaded}');
  /// ```
  ///
  /// **Note:** Progress is tracked via [transferProgress] signal.
  ///
  /// **Limitation:** Currently requires R2 list endpoint implementation.
  /// See [_listCloudFiles] for details.
  Future<SyncResult> syncFromCloud({String? folder}) async {
    if (!isCloudStorageEnabled) {
      return SyncResult(success: false, error: 'Cloud storage not enabled');
    }

    try {
      storageStatus.value = StorageStatus.syncing;

      final cloudFiles = await _listCloudFiles(folder);
      int downloaded = 0;
      int failed = 0;

      for (final file in cloudFiles) {
        try {
          final data = await _downloadFromCloud(file.path);
          if (data != null) {
            await _saveLocalFile(file.path, data);
            downloaded++;
          }
        } catch (e) {
          failed++;
          _logger.warning('Failed to download file: ${file.name}');
        }

        // Update progress
        final progress = (downloaded + failed) / cloudFiles.length;
        transferProgress.value = progress;
      }

      storageStatus.value = StorageStatus.idle;

      return SyncResult(
        success: true,
        filesDownloaded: downloaded,
        filesFailed: failed,
      );
    } catch (e, stackTrace) {
      storageStatus.value = StorageStatus.error;
      _logger.severe('Failed to sync from cloud', e, stackTrace);
      return SyncResult(success: false, error: e.toString());
    } finally {
      transferProgress.value = 0.0;
    }
  }

  // Private Methods

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
          'FileStorageService not initialized. Call initialize() first.');
    }
  }

  String _buildFilePath(String fileName, String? folder) {
    if (folder != null && folder.isNotEmpty) {
      return path.join(folder, fileName);
    }
    return fileName;
  }

  Future<File> _saveLocalFile(String filePath, Uint8List data) async {
    final file = File(path.join(_localStorageDir.path, filePath));

    // Create directory if needed
    final dir = file.parent;
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    await file.writeAsBytes(data);
    _logger.fine('Saved local file: ${file.path}');
    return file;
  }

  Future<Uint8List?> _loadLocalFile(String filePath) async {
    final file = File(path.join(_localStorageDir.path, filePath));

    if (await file.exists()) {
      final data = await file.readAsBytes();
      _logger.fine('Loaded local file: ${file.path}');
      return data;
    }

    return null;
  }

  Future<bool> _deleteLocalFile(String filePath) async {
    final file = File(path.join(_localStorageDir.path, filePath));

    if (await file.exists()) {
      await file.delete();
      _logger.fine('Deleted local file: ${file.path}');
      return true;
    }

    return false;
  }

  Future<List<FileInfo>> _listLocalFiles(String? folder) async {
    final files = <FileInfo>[];

    final searchDir = folder != null
        ? Directory(path.join(_localStorageDir.path, folder))
        : _localStorageDir;

    if (!searchDir.existsSync()) {
      return files;
    }

    final entities = searchDir.listSync(recursive: false);

    for (final entity in entities) {
      if (entity is File) {
        final stat = await entity.stat();
        files.add(FileInfo(
          name: path.basename(entity.path),
          path: path.relative(entity.path, from: _localStorageDir.path),
          size: stat.size,
          modifiedAt: stat.modified,
          isLocal: true,
          isCloud: false,
        ));
      }
    }

    return files;
  }

  Future<FileInfo?> _getLocalFileInfo(String filePath) async {
    final file = File(path.join(_localStorageDir.path, filePath));

    if (await file.exists()) {
      final stat = await file.stat();
      return FileInfo(
        name: path.basename(file.path),
        path: filePath,
        size: stat.size,
        modifiedAt: stat.modified,
        isLocal: true,
        isCloud: false,
      );
    }

    return null;
  }

  Future<String?> _uploadToCloud(
    String filePath,
    Uint8List data,
    Map<String, String>? metadata,
  ) async {
    if (!isCloudStorageEnabled) return null;

    try {
      final cloudflare = _cloudflareService!;

      // Upload file to Cloudflare R2
      final result = await cloudflare.uploadFile(
        bytes: data,
        filename: path.basename(filePath),
        contentType: _getContentType(filePath),
        customKey: '$_defaultBucket/$filePath',
      );

      _logger.fine('Uploaded to cloud: $filePath (key: ${result.key})');
      return result.cdnUrl ?? result.key;
    } catch (e) {
      _logger.severe('Failed to upload to cloud: $filePath - $e');
      rethrow;
    }
  }

  Future<Uint8List?> _downloadFromCloud(String filePath) async {
    if (!isCloudStorageEnabled) return null;

    try {
      final cloudflare = _cloudflareService!;
      final key = '$_defaultBucket/$filePath';

      // Download file from Cloudflare R2
      final data = await cloudflare.downloadFile(key);

      _logger.fine('Downloaded from cloud: $filePath (${data.length} bytes)');
      return data;
    } catch (e) {
      if (e is CloudflareException && e.message.contains('not found')) {
        _logger.fine('File not found in cloud: $filePath');
        return null;
      }
      _logger.warning('Failed to download from cloud: $filePath - $e');
      return null;
    }
  }

  Future<bool> _deleteFromCloud(String filePath) async {
    if (!isCloudStorageEnabled) return false;

    try {
      final cloudflare = _cloudflareService!;
      final key = '$_defaultBucket/$filePath';

      // Delete file from Cloudflare R2
      await cloudflare.deleteFile(key);

      _logger.fine('Deleted from cloud: $filePath');
      return true;
    } catch (e) {
      _logger.warning('Failed to delete from cloud: $filePath - $e');
      return false;
    }
  }

  Future<List<FileInfo>> _listCloudFiles(String? folder) async {
    if (!isCloudStorageEnabled) return [];

    try {
      // TODO: Implement R2 list endpoint in CloudflareService
      // The Cloudflare R2 API supports listing objects, but the CloudflareService
      // doesn't expose this functionality yet. Once implemented, this method
      // should call cloudflare.listFiles(prefix: '$_defaultBucket/${folder ?? ''}')

      _logger.warning(
          'Cloud file listing not yet implemented - requires R2 list endpoint');
      return [];
    } catch (e) {
      _logger.severe('Failed to list cloud files: $e');
      return [];
    }
  }

  Future<FileInfo?> _getCloudFileInfo(String filePath) async {
    if (!isCloudStorageEnabled) return null;

    try {
      final folder = path.dirname(filePath);
      final fileName = path.basename(filePath);

      final files = await _listCloudFiles(folder == '.' ? null : folder);
      return files.firstWhere((f) => f.name == fileName);
    } catch (e) {
      _logger.warning('Failed to get cloud file info: $filePath - $e');
      return null;
    }
  }

  Future<void> _ensureBucketExists(String bucketName) async {
    if (!isCloudStorageEnabled) return;

    // Note: Cloudflare R2 buckets must be created via the Cloudflare dashboard
    // or wrangler CLI. The CloudflareService assumes the bucket already exists.
    // This method is kept for future expansion if bucket creation is needed.

    _logger.fine('Using R2 bucket: $bucketName (assumed to exist)');
  }

  String _getContentType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.json':
        return 'application/json';
      case '.txt':
        return 'text/plain';
      case '.csv':
        return 'text/csv';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get storage statistics
  Future<StorageStats> getStats() async {
    _ensureInitialized();

    int localFiles = 0;
    int localSize = 0;
    int cloudFiles = 0;

    // Count local files and size
    if (_localStorageDir.existsSync()) {
      final entities = _localStorageDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          localFiles++;
          localSize += await entity.length();
        }
      }
    }

    // Count cloud files
    if (isCloudStorageEnabled) {
      try {
        // TODO: Implement cloud file counting when R2 list endpoint is available
        final cloudFilesList = await _listCloudFiles(null);
        cloudFiles = cloudFilesList.length;
      } catch (e) {
        _logger.warning('Failed to get cloud file count: $e');
      }
    }

    return StorageStats(
      localFiles: localFiles,
      localSizeBytes: localSize,
      cloudFiles: cloudFiles,
      isCloudEnabled: isCloudStorageEnabled,
    );
  }
}

/// Storage operation status
enum StorageStatus {
  idle,
  uploading,
  downloading,
  syncing,
  deleting,
  error,
}

/// File information
class FileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime modifiedAt;
  final bool isLocal;
  final bool isCloud;

  FileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedAt,
    required this.isLocal,
    required this.isCloud,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// File storage operation result
class FileStorageResult {
  final bool success;
  final String? localPath;
  final String? cloudUrl;
  final String fileName;
  final int? size;
  final String? error;

  FileStorageResult({
    required this.success,
    this.localPath,
    this.cloudUrl,
    required this.fileName,
    this.size,
    this.error,
  });
}

/// Sync operation result
class SyncResult {
  final bool success;
  final int? filesUploaded;
  final int? filesDownloaded;
  final int? filesFailed;
  final String? error;

  SyncResult({
    required this.success,
    this.filesUploaded,
    this.filesDownloaded,
    this.filesFailed,
    this.error,
  });
}

/// Storage statistics
class StorageStats {
  final int localFiles;
  final int localSizeBytes;
  final int cloudFiles;
  final bool isCloudEnabled;

  StorageStats({
    required this.localFiles,
    required this.localSizeBytes,
    required this.cloudFiles,
    required this.isCloudEnabled,
  });

  double get localSizeMB => localSizeBytes / 1024 / 1024;

  @override
  String toString() {
    return 'StorageStats(local: $localFiles files, ${localSizeMB.toStringAsFixed(2)}MB, cloud: $cloudFiles files, enabled: $isCloudEnabled)';
  }
}

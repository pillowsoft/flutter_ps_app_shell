import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../adaptive_style_provider.dart';

/// Adaptive file picker that follows platform conventions
class AdaptiveFilePicker extends StatefulWidget {
  final List<String>? selectedFiles;
  final Function(List<String>) onFilesSelected;
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final bool showClearButton;
  final bool allowDragDrop;
  final double? maxHeight;

  const AdaptiveFilePicker({
    super.key,
    required this.onFilesSelected,
    this.selectedFiles,
    this.allowMultiple = false,
    this.allowedExtensions,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.prefix,
    this.suffix,
    this.showClearButton = true,
    this.allowDragDrop = true,
    this.maxHeight,
  });

  @override
  State<AdaptiveFilePicker> createState() => _AdaptiveFilePickerState();
}

class _AdaptiveFilePickerState extends State<AdaptiveFilePicker> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertinoFilePicker(context, styleProvider);
      case AdaptivePlatform.forui:
        return _buildForuiFilePicker(context, styleProvider);
      default:
        return _buildMaterialFilePicker(context, styleProvider);
    }
  }

  Widget _buildMaterialFilePicker(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color:
                    widget.errorText != null ? theme.colorScheme.error : null,
              ),
            ),
          ),
        if (widget.allowDragDrop)
          _buildDragDropZone(context, theme)
        else
          _buildClickToSelectButton(context, theme),
        if (widget.selectedFiles?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _buildSelectedFilesList(context, theme),
        ],
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              widget.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCupertinoFilePicker(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.enabled ? _selectFiles : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
              border: widget.errorText != null
                  ? Border.all(color: CupertinoColors.systemRed)
                  : null,
            ),
            child: Row(
              children: [
                if (widget.prefix != null) ...[
                  widget.prefix!,
                  const SizedBox(width: 12),
                ],
                Icon(
                  CupertinoIcons.doc_on_clipboard,
                  color: widget.enabled
                      ? CupertinoColors.label
                      : CupertinoColors.inactiveGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDisplayText(),
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.selectedFiles?.isNotEmpty == true
                          ? (widget.enabled
                              ? CupertinoColors.label
                              : CupertinoColors.inactiveGray)
                          : CupertinoColors.placeholderText,
                    ),
                  ),
                ),
                if (widget.showClearButton &&
                    widget.selectedFiles?.isNotEmpty == true &&
                    widget.enabled)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 24,
                    child: const Icon(CupertinoIcons.clear, size: 20),
                    onPressed: _clearSelection,
                  ),
                if (widget.suffix != null) ...[
                  const SizedBox(width: 12),
                  widget.suffix!,
                ],
              ],
            ),
          ),
        ),
        if (widget.selectedFiles?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _buildCupertinoSelectedFilesList(),
        ],
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForuiFilePicker(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    widget.errorText != null ? theme.colorScheme.error : null,
              ),
            ),
          ),
        if (widget.allowDragDrop)
          _buildForuiDragDropZone(context, theme)
        else
          _buildForuiClickToSelectButton(context, theme),
        if (widget.selectedFiles?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _buildForuiSelectedFilesList(context, theme),
        ],
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              widget.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDragDropZone(BuildContext context, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.maxHeight ?? 120,
      decoration: BoxDecoration(
        color: _isDragOver
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDragOver
              ? theme.colorScheme.primary
              : (widget.errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withValues(alpha: 0.5)),
          width: _isDragOver ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? _selectFiles : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isDragOver
                      ? Icons.file_download
                      : Icons.cloud_upload_outlined,
                  size: 32,
                  color: widget.enabled
                      ? (_isDragOver
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant)
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  _isDragOver
                      ? 'Drop files here'
                      : (widget.hint ?? 'Drag files here or click to browse'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.enabled
                        ? (_isDragOver
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant)
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                    fontWeight: _isDragOver ? FontWeight.w500 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.allowedExtensions?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Allowed: ${widget.allowedExtensions!.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClickToSelectButton(BuildContext context, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled ? _selectFiles : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.enabled
                ? theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              if (widget.prefix != null) ...[
                widget.prefix!,
                const SizedBox(width: 12),
              ],
              Icon(
                Icons.attach_file,
                color: widget.enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getDisplayText(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: widget.selectedFiles?.isNotEmpty == true
                        ? (widget.enabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (widget.showClearButton &&
                  widget.selectedFiles?.isNotEmpty == true &&
                  widget.enabled)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearSelection,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              if (widget.suffix != null) ...[
                const SizedBox(width: 12),
                widget.suffix!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForuiDragDropZone(BuildContext context, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.maxHeight ?? 100,
      decoration: BoxDecoration(
        color: _isDragOver
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isDragOver
              ? theme.colorScheme.primary
              : (widget.errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withValues(alpha: 0.3)),
          width: _isDragOver ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? _selectFiles : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isDragOver ? Icons.download : Icons.upload_file,
                  size: 28,
                  color: widget.enabled
                      ? (_isDragOver
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant)
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  _isDragOver
                      ? 'Drop to upload'
                      : (widget.hint ?? 'Click to select files'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.enabled
                        ? (_isDragOver
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant)
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForuiClickToSelectButton(BuildContext context, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled ? _selectFiles : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: widget.enabled
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              if (widget.prefix != null) ...[
                widget.prefix!,
                const SizedBox(width: 12),
              ],
              Icon(
                Icons.attach_file,
                size: 20,
                color: widget.enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getDisplayText(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: widget.selectedFiles?.isNotEmpty == true
                        ? (widget.enabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.showClearButton &&
                  widget.selectedFiles?.isNotEmpty == true &&
                  widget.enabled)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clearSelection,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              if (widget.suffix != null) ...[
                const SizedBox(width: 12),
                widget.suffix!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFilesList(BuildContext context, ThemeData theme) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight ?? 200),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widget.selectedFiles!.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final fileName = widget.selectedFiles![index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getFileIcon(fileName),
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.enabled)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => _removeFile(index),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCupertinoSelectedFilesList() {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight ?? 200),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widget.selectedFiles!.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final fileName = widget.selectedFiles![index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getCupertinoFileIcon(fileName),
                  size: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.enabled)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 20,
                    child: const Icon(CupertinoIcons.clear, size: 16),
                    onPressed: () => _removeFile(index),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForuiSelectedFilesList(BuildContext context, ThemeData theme) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight ?? 200),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widget.selectedFiles!.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final fileName = widget.selectedFiles![index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  _getFileIcon(fileName),
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.enabled)
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: () => _removeFile(index),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getDisplayText() {
    if (widget.selectedFiles?.isNotEmpty == true) {
      final count = widget.selectedFiles!.length;
      if (count == 1) {
        return widget.selectedFiles!.first;
      } else {
        return '$count files selected';
      }
    }
    return widget.hint ?? 'Select ${widget.allowMultiple ? 'files' : 'file'}';
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getCupertinoFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return CupertinoIcons.photo;
      case 'pdf':
        return CupertinoIcons.doc_text;
      case 'doc':
      case 'docx':
        return CupertinoIcons.doc;
      case 'zip':
      case 'rar':
        return CupertinoIcons.archivebox;
      case 'mp4':
      case 'mov':
      case 'avi':
        return CupertinoIcons.play;
      case 'mp3':
      case 'wav':
        return CupertinoIcons.music_note;
      default:
        return CupertinoIcons.doc;
    }
  }

  void _selectFiles() {
    // In a real implementation, this would use file_picker package
    // For now, simulate file selection
    final simulatedFiles = widget.allowMultiple
        ? ['document1.pdf', 'image.jpg', 'data.xlsx']
        : ['document.pdf'];

    widget.onFilesSelected(simulatedFiles);
  }

  void _removeFile(int index) {
    final updatedFiles = List<String>.from(widget.selectedFiles ?? []);
    updatedFiles.removeAt(index);
    widget.onFilesSelected(updatedFiles);
  }

  void _clearSelection() {
    widget.onFilesSelected([]);
  }
}

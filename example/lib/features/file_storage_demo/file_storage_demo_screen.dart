import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class FileStorageDemoScreen extends StatefulWidget {
  const FileStorageDemoScreen({super.key});

  @override
  State<FileStorageDemoScreen> createState() => _FileStorageDemoScreenState();
}

class _FileStorageDemoScreenState extends State<FileStorageDemoScreen> {
  final _fileNameController = TextEditingController();
  final _contentController = TextEditingController();
  String _result = '';
  List<String> _localFiles = [];

  @override
  void initState() {
    super.initState();
    _loadLocalFiles();
  }

  Future<void> _loadLocalFiles() async {
    try {
      final fileService = getIt<FileStorageService>();
      final files = await fileService.listLocalFiles();
      setState(() {
        _localFiles = files;
      });
    } catch (e) {
      setState(() => _result = 'Error loading files: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ui.pageTitle('File Storage Demo'),
        const SizedBox(height: 8),
        Text(
          'Local and cloud file management',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),

        // Save File Section
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save File',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ui.textField(
                  controller: _fileNameController,
                  labelText: 'File Name',
                  hintText: 'example.txt',
                ),
                const SizedBox(height: 16),
                ui.textField(
                  controller: _contentController,
                  labelText: 'Content',
                  hintText: 'Enter file content',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ui.button(
                  label: 'Save File',
                  onPressed: _saveFile,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Local Files Section
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Local Files (${_localFiles.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ui.iconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadLocalFiles,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_localFiles.isEmpty)
                  const Text('No files yet')
                else
                  ..._localFiles.map((file) => ui.listTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(file),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ui.iconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _readFile(file),
                            ),
                            ui.iconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteFile(file),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),

        if (_result.isNotEmpty) ...[
          const SizedBox(height: 24),
          ui.card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Result',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_result),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveFile() async {
    if (_fileNameController.text.isEmpty || _contentController.text.isEmpty) {
      setState(() => _result = 'Please enter file name and content');
      return;
    }

    try {
      final fileService = getIt<FileStorageService>();
      await fileService.writeTextFile(
        _fileNameController.text,
        _contentController.text,
      );

      setState(() => _result = '✅ File saved: ${_fileNameController.text}');
      _fileNameController.clear();
      _contentController.clear();
      _loadLocalFiles();
    } catch (e) {
      setState(() => _result = '❌ Error saving file: $e');
    }
  }

  Future<void> _readFile(String fileName) async {
    try {
      final fileService = getIt<FileStorageService>();
      final content = await fileService.readTextFile(fileName);
      setState(() => _result = '📄 $fileName:\n\n$content');
    } catch (e) {
      setState(() => _result = '❌ Error reading file: $e');
    }
  }

  Future<void> _deleteFile(String fileName) async {
    try {
      final fileService = getIt<FileStorageService>();
      await fileService.deleteFile(fileName);
      setState(() => _result = '✅ File deleted: $fileName');
      _loadLocalFiles();
    } catch (e) {
      setState(() => _result = '❌ Error deleting file: $e');
    }
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

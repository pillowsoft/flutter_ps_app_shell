import 'dart:io';
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as path;

/// Represents a parsed documentation file.
class DocFile {
  final String relativePath;
  final String title;
  final String description;
  final String content;
  final int priority;

  const DocFile({
    required this.relativePath,
    required this.title,
    required this.description,
    required this.content,
    required this.priority,
  });

  @override
  String toString() => 'DocFile($relativePath, $title, priority: $priority)';
}

/// Configuration for a documentation file.
class DocFileConfig {
  final String title;
  final String description;
  final int priority;

  const DocFileConfig({
    required this.title,
    required this.description,
    required this.priority,
  });
}

/// Parses documentation files for llms.txt generation.
class DocParser {
  final Directory docsDirectory;
  final bool verbose;

  const DocParser({
    required this.docsDirectory,
    this.verbose = false,
  });

  /// Parse all documentation files according to configuration.
  Future<List<DocFile>> parseDocumentation() async {
    if (verbose) {
      print('📚 Parsing documentation files from ${docsDirectory.path}...');
    }

    final docFiles = <DocFile>[];
    final fileConfigs = _getFileConfigurations();

    for (final entry in fileConfigs.entries) {
      final relativePath = entry.key;
      final config = entry.value;
      final filePath = File(path.join(docsDirectory.path, relativePath));

      if (await filePath.exists()) {
        try {
          final content = await _readAndCleanFile(filePath);
          docFiles.add(DocFile(
            relativePath: relativePath,
            title: config.title,
            description: config.description,
            content: content,
            priority: config.priority,
          ));

          if (verbose) {
            print('   ✓ $relativePath');
          }
        } catch (e) {
          print('   ⚠️  Error reading $relativePath: $e');
        }
      } else {
        if (verbose) {
          print('   ⚠️  File not found: $relativePath');
        }
      }
    }

    // Sort by priority (most important first)
    docFiles.sort((a, b) => a.priority.compareTo(b.priority));

    if (verbose) {
      print('📄 Parsed ${docFiles.length} documentation files');
    }

    return docFiles;
  }

  /// Read and clean a markdown file for optimal LLM consumption.
  Future<String> _readAndCleanFile(File file) async {
    final content = await file.readAsString();
    return _cleanMarkdownContent(content);
  }

  /// Clean markdown content for optimal LLM consumption.
  String _cleanMarkdownContent(String content) {
    var cleaned = content;

    // Remove table of contents sections
    cleaned = cleaned.replaceAll(
      RegExp(r'## 🎯 Table of Contents.*?(?=##|\Z)', dotAll: true),
      '',
    );

    // Remove navigation breadcrumbs
    cleaned = cleaned.replaceAll(RegExp(r'\*\*Next:\*\*.*?(?=\n|\Z)'), '');
    cleaned =
        cleaned.replaceAll(RegExp(r'---\n\n\*Last updated:.*?(?=\n|\Z)'), '');

    // Remove excessive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove HTML comments
    cleaned = cleaned.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

    // Remove system reminder tags if present
    cleaned = cleaned.replaceAll(
        RegExp(r'<system-reminder>.*?</system-reminder>', dotAll: true), '');

    return cleaned.trim();
  }

  /// Get file configurations with priorities and descriptions.
  Map<String, DocFileConfig> _getFileConfigurations() {
    return {
      'README.md': const DocFileConfig(
        title: 'Documentation Index',
        description:
            'Complete navigation hub for all Flutter App Shell documentation',
        priority: 1,
      ),
      'getting-started.md': const DocFileConfig(
        title: 'Getting Started Guide',
        description:
            'Step-by-step tutorial to build your first app in 5-10 minutes',
        priority: 1,
      ),
      'architecture.md': const DocFileConfig(
        title: 'Architecture Overview',
        description:
            'Service-oriented architecture, adaptive UI, and reactive state management principles',
        priority: 2,
      ),
      'ui-systems/README.md': const DocFileConfig(
        title: 'Adaptive UI Systems',
        description:
            'Complete guide to Material, Cupertino, and ForUI with implementation details',
        priority: 2,
      ),
      'services/README.md': const DocFileConfig(
        title: 'Services Documentation',
        description:
            'Overview of all 30+ services with architecture patterns and integration guide',
        priority: 2,
      ),
      'examples/patterns.md': const DocFileConfig(
        title: 'Common Patterns & Examples',
        description:
            'Real-world code examples for authentication, data management, UI patterns, and performance',
        priority: 3,
      ),
      'migration-guide.md': const DocFileConfig(
        title: 'Migration Guide',
        description:
            'Comprehensive guide for migrating existing Flutter apps with proven strategies',
        priority: 3,
      ),
      'reference/best-practices.md': const DocFileConfig(
        title: 'Best Practices & Guidelines',
        description:
            'Guidelines for maintainable, performant code with common pitfalls to avoid',
        priority: 3,
      ),
      'services/database.md': const DocFileConfig(
        title: 'Database Service',
        description:
            'NoSQL document database with reactive queries, cloud sync, and offline-first architecture',
        priority: 4,
      ),
      'flutter_app_shell_spec.md': const DocFileConfig(
        title: 'Framework Specification',
        description:
            'Comprehensive technical specification and design document',
        priority: 5,
      ),
    };
  }
}

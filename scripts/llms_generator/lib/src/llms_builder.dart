import 'dart:io';
import 'package:path/path.dart' as path;
import 'doc_parser.dart';

/// Builds llms.txt files from parsed documentation.
class LLMsBuilder {
  final Directory outputDirectory;
  final bool verbose;

  const LLMsBuilder({
    required this.outputDirectory,
    this.verbose = false,
  });

  /// Generate both llms.txt and llms-full.txt files.
  Future<void> buildLLMsFiles(List<DocFile> docFiles) async {
    if (verbose) {
      print('📝 Building llms.txt files...');
    }

    await _buildNavigationIndex(docFiles);
    await _buildFullContent(docFiles);

    if (verbose) {
      print('✅ Successfully generated llms.txt files!');
      print('   📄 ${path.join(outputDirectory.path, 'llms.txt')}');
      print('   📄 ${path.join(outputDirectory.path, 'llms-full.txt')}');
    }
  }

  /// Generate the navigation index llms.txt file.
  Future<void> _buildNavigationIndex(List<DocFile> docFiles) async {
    final content = _buildNavigationContent(docFiles);
    final outputFile = File(path.join(outputDirectory.path, 'llms.txt'));
    await outputFile.writeAsString(content);

    if (verbose) {
      print('   ✓ llms.txt (navigation index)');
    }
  }

  /// Generate the complete content llms-full.txt file.
  Future<void> _buildFullContent(List<DocFile> docFiles) async {
    final content = _buildFullContentString(docFiles);
    final outputFile = File(path.join(outputDirectory.path, 'llms-full.txt'));
    await outputFile.writeAsString(content);

    if (verbose) {
      print('   ✓ llms-full.txt (complete content)');
    }
  }

  /// Build the navigation index content following llms.txt specification.
  String _buildNavigationContent(List<DocFile> docFiles) {
    final buffer = StringBuffer();

    // H1 title (required)
    buffer.writeln('# Flutter App Shell\n');

    // Blockquote summary (required)
    buffer.write(
        '> A comprehensive Flutter application framework for rapid development with adaptive UI, ');
    buffer.write(
        'service architecture, state management, and cloud synchronization capabilities. ');
    buffer.write(
        'Zero-configuration setup with 30+ built-in services, complete UI system switching ');
    buffer.write(
        '(Material/Cupertino/ForUI), offline-first architecture with cloud sync, and reactive ');
    buffer.writeln('state management using Signals.\n');

    buffer.writeln('Key Features:');
    buffer.writeln(
        '- 🚀 **5-minute app creation** - Single function call creates fully-featured app');
    buffer.writeln(
        '- 🎨 **Complete UI system switching** - Entire app adapts between Material, Cupertino, and ForUI design systems');
    buffer.writeln(
        '- 🔧 **30+ built-in services** - Authentication, database, networking, file storage, preferences, and more');
    buffer.writeln(
        '- 📱 **Responsive navigation** - Automatic adaptation: bottom tabs → navigation rail → sidebar');
    buffer.writeln(
        '- ☁️ **Offline-first architecture** - Local database with automatic cloud sync via Supabase');
    buffer.writeln(
        '- 🔄 **Reactive state management** - Signals-based reactivity with granular UI updates');
    buffer.writeln(
        '- 🛠️ **Service inspector** - Real-time debugging and monitoring of all services\n');

    // Core sections with links to existing documentation
    final sections = [
      _NavigationSection('## Getting Started', [
        _NavigationLink('Getting Started Guide', 'docs/getting-started.md',
            'Step-by-step tutorial to build your first app in 5-10 minutes with working code examples'),
      ]),
      _NavigationSection('## Architecture & Core Concepts', [
        _NavigationLink('Architecture Overview', 'docs/architecture.md',
            'Service-oriented architecture, dependency injection, adaptive UI factory pattern, and reactive state management'),
        _NavigationLink('Services Documentation', 'docs/services/README.md',
            'Complete guide to 30+ built-in services including database, authentication, networking, and file storage'),
        _NavigationLink(
            'Framework Specification',
            'docs/flutter_app_shell_spec.md',
            'Comprehensive technical specification covering all framework components and design decisions'),
      ]),
      _NavigationSection('## UI & Design Systems', [
        _NavigationLink('Adaptive UI Systems', 'docs/ui-systems/README.md',
            'Complete guide to Material, Cupertino, and ForUI with factory pattern implementation and visual examples'),
      ]),
      _NavigationSection('## Implementation Guides', [
        _NavigationLink('Common Patterns', 'docs/examples/patterns.md',
            'Real-world code examples for authentication flows, data management, UI composition, navigation, and performance optimization'),
        _NavigationLink('Best Practices', 'docs/reference/best-practices.md',
            'Guidelines for maintainable, performant code with common pitfalls to avoid and recommended patterns'),
        _NavigationLink('Migration Guide', 'docs/migration-guide.md',
            'Comprehensive guide for migrating existing Flutter apps with incremental adoption strategies'),
      ]),
      _NavigationSection('## Optional', [
        _NavigationLink('Database Service', 'docs/services/database.md',
            'NoSQL document database with Isar backend, reactive queries, cloud sync, and conflict resolution'),
      ]),
    ];

    // Build sections with only existing files
    for (final section in sections) {
      buffer.writeln(section.title);
      for (final link in section.links) {
        // Only include links that exist in our parsed files
        if (docFiles.any((doc) => link.path.endsWith(doc.relativePath))) {
          buffer
              .writeln('- [${link.title}](${link.path}) - ${link.description}');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Build the complete content string for llms-full.txt.
  String _buildFullContentString(List<DocFile> docFiles) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# Flutter App Shell - Complete Documentation\n');

    // Summary
    buffer.write(
        '> A comprehensive Flutter application framework for rapid development with adaptive UI, ');
    buffer.write(
        'service architecture, state management, and cloud synchronization capabilities. ');
    buffer.writeln(
        'This document contains the complete framework documentation optimized for large language model consumption.\n');

    buffer.writeln('## Framework Overview\n');
    buffer.writeln(
        'Flutter App Shell provides a zero-configuration foundation for Flutter applications with:\n');
    buffer.writeln(
        '- **Service-Oriented Architecture**: Dependency injection with GetIt, reactive services, health monitoring');
    buffer.writeln(
        '- **Adaptive UI System**: Complete runtime switching between Material, Cupertino, and ForUI design systems');
    buffer.writeln(
        '- **Reactive State Management**: Signals-based reactivity with granular UI updates and automatic persistence');
    buffer.writeln(
        '- **Responsive Navigation**: Automatic layout adaptation (bottom tabs → navigation rail → sidebar)');
    buffer.writeln(
        '- **Offline-First Data**: Local Isar database with automatic Supabase cloud sync and conflict resolution');
    buffer.writeln(
        '- **30+ Built-in Services**: Authentication, database, networking, file storage, preferences, and more\n');

    // Add each documentation file's content
    for (final doc in docFiles) {
      if (doc.content.trim().isNotEmpty) {
        buffer.writeln('---\n');
        buffer.writeln('## ${doc.title}\n');
        buffer.writeln('*${doc.description}*\n');
        buffer.writeln(doc.content);
        buffer.writeln('\n');
      }
    }

    // Add implementation quick reference
    buffer.writeln(_buildQuickReference());

    return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  /// Build a quick reference section for common patterns.
  String _buildQuickReference() {
    return '''---

## Quick Reference for AI Development

### Basic App Setup
```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() {
  runShellApp(() async {
    return AppConfig(
      title: 'My App',
      routes: [
        AppRoute(
          title: 'Home',
          path: '/',
          icon: Icons.home,
          builder: (context, state) => HomeScreen(),
        ),
      ],
    );
  });
}
```

### Using Services
```dart
// Get service from dependency injection
final db = getIt<DatabaseService>();
final auth = getIt<AuthenticationService>();

// Create reactive data
await db.create('todos', {
  'title': 'Buy groceries',
  'completed': false,
});

// Watch for changes
db.watchByType('todos').listen((documents) {
  print('Todos updated: \${documents.length}');
});
```

### Adaptive UI Pattern
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    return ui.scaffold(
      body: Column(
        children: [
          ui.button(
            label: 'Adaptive Button',
            onPressed: () {},
          ),
          ui.textField(
            labelText: 'Adaptive Input',
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}
```

### Reactive State with Signals
```dart
// Create reactive state
final counter = signal(0);

// Watch in UI (automatically rebuilds)
Watch((context) => Text('Count: \${counter.value}'))

// Update from anywhere
counter.value++;
```

### Key Patterns to Follow
1. **Always use adaptive factory**: `getAdaptiveFactory(context)` instead of platform-specific widgets
2. **Service-first architecture**: Business logic in services, not widgets
3. **Reactive UI**: Use `Watch()` widgets for automatic updates
4. **Dependency injection**: Access services via `getIt<ServiceType>()`
5. **Offline-first**: Local database with automatic cloud sync

This framework follows Material Design, iOS Human Interface Guidelines, and modern minimalist design principles depending on the selected UI system.
''';
  }
}

/// Navigation section for llms.txt structure.
class _NavigationSection {
  final String title;
  final List<_NavigationLink> links;

  const _NavigationSection(this.title, this.links);
}

/// Navigation link for llms.txt structure.
class _NavigationLink {
  final String title;
  final String path;
  final String description;

  const _NavigationLink(this.title, this.path, this.description);
}

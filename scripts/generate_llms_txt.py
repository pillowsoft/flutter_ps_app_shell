#!/usr/bin/env python3
"""
Generate llms.txt files for Flutter App Shell framework.

This script creates both /llms.txt (navigation index) and /llms-full.txt (complete content)
files following the official llms.txt specification from llmstxt.org.

Usage:
    python scripts/generate_llms_txt.py
"""

import os
import re
from pathlib import Path
from typing import Dict, List, Tuple
from dataclasses import dataclass


@dataclass
class DocFile:
    """Represents a documentation file."""
    path: str
    title: str
    description: str
    content: str
    priority: int = 5  # 1 = highest priority, 10 = lowest


class LLMsTxtGenerator:
    """Generates llms.txt files from Flutter App Shell documentation."""
    
    def __init__(self, docs_dir: str = "docs", output_dir: str = "."):
        self.docs_dir = Path(docs_dir)
        self.output_dir = Path(output_dir)
        self.doc_files: List[DocFile] = []
        
    def run(self):
        """Main execution method."""
        print("🚀 Generating llms.txt files for Flutter App Shell...")
        
        # Parse all documentation files
        self._parse_documentation()
        
        # Generate both llms.txt files
        self._generate_llms_txt()
        self._generate_llms_full_txt()
        
        print("✅ Successfully generated llms.txt files!")
        print(f"   📄 {self.output_dir}/llms.txt")
        print(f"   📄 {self.output_dir}/llms-full.txt")
        
    def _parse_documentation(self):
        """Parse all markdown files in the docs directory."""
        print("📚 Parsing documentation files...")
        
        # Define file priorities and descriptions
        file_config = {
            "README.md": {
                "title": "Documentation Index",
                "description": "Complete navigation hub for all Flutter App Shell documentation",
                "priority": 1
            },
            "getting-started.md": {
                "title": "Getting Started Guide", 
                "description": "Step-by-step tutorial to build your first app in 5-10 minutes",
                "priority": 1
            },
            "architecture.md": {
                "title": "Architecture Overview",
                "description": "Service-oriented architecture, adaptive UI, and reactive state management principles",
                "priority": 2
            },
            "ui-systems/README.md": {
                "title": "Adaptive UI Systems",
                "description": "Complete guide to Material, Cupertino, and ForUI with implementation details",
                "priority": 2
            },
            "services/README.md": {
                "title": "Services Documentation",
                "description": "Overview of all 30+ services with architecture patterns and integration guide",
                "priority": 2
            },
            "examples/patterns.md": {
                "title": "Common Patterns & Examples",
                "description": "Real-world code examples for authentication, data management, UI patterns, and performance",
                "priority": 3
            },
            "migration-guide.md": {
                "title": "Migration Guide",
                "description": "Comprehensive guide for migrating existing Flutter apps with proven strategies",
                "priority": 3
            },
            "reference/best-practices.md": {
                "title": "Best Practices & Guidelines",
                "description": "Guidelines for maintainable, performant code with common pitfalls to avoid",
                "priority": 3
            },
            "services/database.md": {
                "title": "Database Service",
                "description": "NoSQL document database with reactive queries, cloud sync, and offline-first architecture",
                "priority": 4
            },
            "flutter_app_shell_spec.md": {
                "title": "Framework Specification",
                "description": "Comprehensive technical specification and design document",
                "priority": 5
            }
        }
        
        # Parse each documented file
        for relative_path, config in file_config.items():
            file_path = self.docs_dir / relative_path
            if file_path.exists():
                content = self._read_file(file_path)
                self.doc_files.append(DocFile(
                    path=relative_path,
                    title=config["title"],
                    description=config["description"],
                    content=content,
                    priority=config["priority"]
                ))
                print(f"   ✓ {relative_path}")
        
        # Sort by priority (most important first)
        self.doc_files.sort(key=lambda x: x.priority)
        
    def _read_file(self, file_path: Path) -> str:
        """Read and clean a markdown file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Clean up content for LLM consumption
            content = self._clean_markdown_content(content)
            return content
            
        except Exception as e:
            print(f"⚠️  Error reading {file_path}: {e}")
            return ""
    
    def _clean_markdown_content(self, content: str) -> str:
        """Clean markdown content for optimal LLM consumption."""
        # Remove table of contents links
        content = re.sub(r'## 🎯 Table of Contents.*?(?=##|\Z)', '', content, flags=re.DOTALL)
        
        # Remove navigation breadcrumbs
        content = re.sub(r'\*\*Next:\*\*.*?(?=\n|\Z)', '', content)
        content = re.sub(r'---\n\n\*Last updated:.*?(?=\n|\Z)', '', content)
        
        # Clean up excessive whitespace
        content = re.sub(r'\n{3,}', '\n\n', content)
        
        # Remove HTML comments
        content = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
        
        return content.strip()
    
    def _generate_llms_txt(self):
        """Generate the navigation index /llms.txt file."""
        print("📝 Generating /llms.txt (navigation index)...")
        
        content = self._build_llms_txt_content()
        
        output_file = self.output_dir / "llms.txt"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
    
    def _build_llms_txt_content(self) -> str:
        """Build the content for llms.txt following the official specification."""
        
        # H1 title (required)
        title = "# Flutter App Shell\n\n"
        
        # Blockquote summary (required)
        summary = """> A comprehensive Flutter application framework for rapid development with adaptive UI, service architecture, state management, and cloud synchronization capabilities. Zero-configuration setup with 30+ built-in services, complete UI system switching (Material/Cupertino/ForUI), offline-first architecture with cloud sync, and reactive state management using Signals.

Key Features:
- 🚀 **5-minute app creation** - Single function call creates fully-featured app
- 🎨 **Complete UI system switching** - Entire app adapts between Material, Cupertino, and ForUI design systems  
- 🔧 **30+ built-in services** - Authentication, database, networking, file storage, preferences, and more
- 📱 **Responsive navigation** - Automatic adaptation: bottom tabs → navigation rail → sidebar
- ☁️ **Offline-first architecture** - Local database with automatic cloud sync via Supabase
- 🔄 **Reactive state management** - Signals-based reactivity with granular UI updates
- 🛠️ **Service inspector** - Real-time debugging and monitoring of all services

"""
        
        # Core sections
        sections = [
            ("## Getting Started", [
                ("Getting Started Guide", "docs/getting-started.md", "Step-by-step tutorial to build your first app in 5-10 minutes with working code examples"),
                ("Installation & Setup", "docs/installation.md", "Detailed installation instructions and project setup")
            ]),
            
            ("## Architecture & Core Concepts", [
                ("Architecture Overview", "docs/architecture.md", "Service-oriented architecture, dependency injection, adaptive UI factory pattern, and reactive state management"),
                ("Services Documentation", "docs/services/README.md", "Complete guide to 30+ built-in services including database, authentication, networking, and file storage"),
                ("Framework Specification", "docs/flutter_app_shell_spec.md", "Comprehensive technical specification covering all framework components and design decisions")
            ]),
            
            ("## UI & Design Systems", [
                ("Adaptive UI Systems", "docs/ui-systems/README.md", "Complete guide to Material, Cupertino, and ForUI with factory pattern implementation and visual examples"),
                ("Component Library", "docs/ui-systems/components.md", "30+ adaptive widgets with platform-specific implementations and usage examples")
            ]),
            
            ("## Implementation Guides", [
                ("Common Patterns", "docs/examples/patterns.md", "Real-world code examples for authentication flows, data management, UI composition, navigation, and performance optimization"),
                ("Best Practices", "docs/reference/best-practices.md", "Guidelines for maintainable, performant code with common pitfalls to avoid and recommended patterns"),
                ("Migration Guide", "docs/migration-guide.md", "Comprehensive guide for migrating existing Flutter apps with incremental adoption strategies")
            ]),
            
            ("## Optional", [
                ("Database Service", "docs/services/database.md", "NoSQL document database with Isar backend, reactive queries, cloud sync, and conflict resolution"),
                ("API Reference", "docs/api/README.md", "Complete API documentation for all services and components"),
                ("Advanced Topics", "docs/advanced/README.md", "Custom services, performance optimization, and extending the framework")
            ])
        ]
        
        # Build sections
        content_parts = [title, summary]
        
        for section_title, links in sections:
            content_parts.append(f"{section_title}\n")
            for link_title, link_path, description in links:
                # Only include links that exist in our parsed files
                if any(doc.path == link_path.replace("docs/", "") for doc in self.doc_files):
                    content_parts.append(f"- [{link_title}]({link_path}) - {description}\n")
            content_parts.append("\n")
        
        return "".join(content_parts)
    
    def _generate_llms_full_txt(self):
        """Generate the complete content /llms-full.txt file."""
        print("📄 Generating /llms-full.txt (complete content)...")
        
        content_parts = [
            "# Flutter App Shell - Complete Documentation\n\n",
            
            # Summary
            """> A comprehensive Flutter application framework for rapid development with adaptive UI, service architecture, state management, and cloud synchronization capabilities. This document contains the complete framework documentation optimized for large language model consumption.

## Framework Overview

Flutter App Shell provides a zero-configuration foundation for Flutter applications with:

- **Service-Oriented Architecture**: Dependency injection with GetIt, reactive services, health monitoring
- **Adaptive UI System**: Complete runtime switching between Material, Cupertino, and ForUI design systems
- **Reactive State Management**: Signals-based reactivity with granular UI updates and automatic persistence
- **Responsive Navigation**: Automatic layout adaptation (bottom tabs → navigation rail → sidebar)
- **Offline-First Data**: Local Isar database with automatic Supabase cloud sync and conflict resolution
- **30+ Built-in Services**: Authentication, database, networking, file storage, preferences, and more

""",
        ]
        
        # Add each documentation file's content
        for doc in self.doc_files:
            if doc.content.strip():
                content_parts.append(f"\n---\n\n## {doc.title}\n\n")
                content_parts.append(f"*{doc.description}*\n\n")
                content_parts.append(doc.content)
                content_parts.append("\n\n")
        
        # Add implementation quick reference
        content_parts.append(self._build_quick_reference())
        
        full_content = "".join(content_parts)
        
        # Clean up the final content
        full_content = re.sub(r'\n{3,}', '\n\n', full_content)
        
        output_file = self.output_dir / "llms-full.txt"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(full_content)
    
    def _build_quick_reference(self) -> str:
        """Build a quick reference section for common patterns."""
        return """---

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
  print('Todos updated: ${documents.length}');
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
Watch((context) => Text('Count: ${counter.value}'))

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
"""


def main():
    """Main entry point."""
    # Change to project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    os.chdir(project_root)
    
    # Generate llms.txt files
    generator = LLMsTxtGenerator()
    generator.run()


if __name__ == "__main__":
    main()
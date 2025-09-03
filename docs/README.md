# Flutter App Shell Documentation

Welcome to the comprehensive documentation for Flutter App Shell - a powerful framework for rapid Flutter development with adaptive UI, service architecture, and cloud integration.

## 📚 Documentation Index

### Getting Started
- [Getting Started Guide](getting-started.md) - Step-by-step tutorial for your first app
- [Installation & Setup](installation.md) - Detailed installation instructions
- [Quick Start Examples](quickstart-examples.md) - Common use cases and code snippets

### AI-Friendly Documentation
- **[llms.txt](../llms.txt)** - Navigation index optimized for AI consumption ([llms.txt spec](https://llmstxt.org))
- **[llms-full.txt](../llms-full.txt)** - Complete documentation for AI development
- **[Generate llms.txt](#generating-llmstxt-files)** - Instructions for updating AI-friendly docs

### Core Concepts
- [Architecture Overview](architecture.md) - Framework architecture and design principles
- [Service Layer](services/README.md) - Understanding the service-oriented architecture
- [State Management](state-management.md) - Signals-first reactive state management
- [Navigation System](navigation.md) - Responsive navigation and routing

### UI & Design Systems
- [Adaptive UI Overview](ui-systems/README.md) - Complete guide to adaptive UI systems
- [Material Design](ui-systems/material.md) - Material Design implementation
- [Cupertino (iOS)](ui-systems/cupertino.md) - iOS-style components and behavior
- [ForUI](ui-systems/forui.md) - Modern minimal design system
- [Component Library](ui-systems/components.md) - Complete component reference
- [Dialogs](ui-systems/dialogs.md) - Platform-adaptive dialog system
- [SnackBars](ui-systems/snackbars.md) - Platform-adaptive notifications

### Services Documentation
- [Services Overview](services/README.md) - All available services
- [Database Service](services/database.md) - Local storage with cloud sync
- [Authentication Service](services/authentication.md) - User authentication and management
- [Network Service](services/networking.md) - HTTP client with offline support
- [File Storage Service](services/file-storage.md) - Local and cloud file management
- [Preferences Service](services/preferences.md) - Settings and user preferences
- [Navigation Service](services/navigation.md) - Centralized navigation management
- [Service Inspector](services/inspector.md) - Real-time debugging and monitoring

### Cloud Integration
- [InstantDB Integration](cloud/instantdb.md) - Complete InstantDB setup and usage
- [Offline-First Architecture](cloud/offline-first.md) - Local-first with cloud sync
- [Real-time Features](cloud/realtime.md) - Live updates and subscriptions
- [Conflict Resolution](cloud/conflict-resolution.md) - Handling concurrent modifications

### Plugin System
- [Plugin System Overview](plugin-system.md) - Comprehensive plugin architecture
- [Creating Plugins](plugins/creating-plugins.md) - Plugin development guide
- [Service Plugins](plugins/service-plugins.md) - Business logic extensions
- [Widget Plugins](plugins/widget-plugins.md) - UI component extensions
- [Theme Plugins](plugins/theme-plugins.md) - Custom UI systems
- [Workflow Plugins](plugins/workflow-plugins.md) - Automation and processing

### Advanced Topics
- [Custom Services](advanced/custom-services.md) - Creating your own services
- [Extending the Framework](advanced/extending.md) - Adding new functionality
- [Performance Optimization](advanced/performance.md) - Best practices for performance
- [Testing Strategies](advanced/testing.md) - Testing framework components

### Examples & Patterns
- [Common Patterns](examples/patterns.md) - Recommended implementation patterns
- [Real-world Examples](examples/real-world.md) - Complete example applications
- [Code Snippets](examples/snippets.md) - Useful code snippets and utilities
- [Migration Examples](examples/migration.md) - Migrating existing apps

### Reference
- [API Reference](api/README.md) - Complete API documentation
- [Configuration Options](reference/configuration.md) - All configuration options
- [Environment Variables](reference/environment.md) - Environment configuration
- [Troubleshooting](reference/troubleshooting.md) - Common issues and solutions

### Contributing
- [Contributing Guide](contributing/README.md) - How to contribute to the framework
- [Development Setup](contributing/development.md) - Setting up development environment
- [Code Standards](contributing/standards.md) - Coding standards and conventions

## 🚀 Quick Navigation

### New to Flutter App Shell?
1. [Getting Started Guide](getting-started.md)
2. [Architecture Overview](architecture.md)
3. [Quick Start Examples](quickstart-examples.md)

### Building Your First App?
1. [Installation & Setup](installation.md)
2. [Basic App Structure](examples/basic-app.md)
3. [Adding Services](services/README.md)

### Looking for Specific Features?
- **Adaptive UI**: [UI Systems Guide](ui-systems/README.md)
- **Database**: [Database Service](services/database.md)
- **Authentication**: [Authentication Service](services/authentication.md)
- **Cloud Sync**: [InstantDB Integration](cloud/instantdb.md)
- **Navigation**: [Navigation System](navigation.md)
- **Plugins**: [Plugin System](plugin-system.md)

### Need Help?
- [Troubleshooting Guide](reference/troubleshooting.md)
- [FAQ](reference/faq.md)
- [Community Support](contributing/support.md)

## 📖 Documentation Format

This documentation uses the following conventions:

- **💡 Tips** - Helpful hints and best practices
- **⚠️ Important** - Critical information and warnings
- **📝 Examples** - Code examples and implementations
- **🔗 References** - Links to related documentation

## 🤖 Generating llms.txt Files

Flutter App Shell includes an AI-friendly documentation format called [llms.txt](https://llmstxt.org) that makes it easy for large language models to understand and use the framework.

### What are llms.txt files?

- **`llms.txt`** - Navigation index optimized for AI consumption
- **`llms-full.txt`** - Complete documentation content for comprehensive AI understanding

### Generating llms.txt Files

Use the built-in Dart CLI tool to generate updated llms.txt files:

```bash
# Generate llms.txt files (requires Dart SDK)
just generate-llms

# Or build the generator and run it
just setup-llms

# Manual generation with custom options
./generate_llms_txt --verbose --docs-dir docs --output-dir .
```

### Using llms.txt for AI Development

Share the `llms.txt` or `llms-full.txt` files with AI assistants like Claude, ChatGPT, or others to help them understand the Flutter App Shell framework and assist with development.

**Example prompt:**
```
I'm working with Flutter App Shell. Here's the complete documentation:

[Paste contents of llms-full.txt here]

Please help me create a new app with authentication and a todo list.
```

### Keeping llms.txt Updated

The llms.txt files are automatically generated from the markdown documentation in the `docs/` directory. When you update documentation:

1. Make changes to the relevant `.md` files in `docs/`
2. Run `just generate-llms` to update the llms.txt files
3. Commit both the documentation changes and updated llms.txt files

## 🤝 Contributing to Documentation

Found an error or want to improve the documentation? See our [Contributing Guide](contributing/README.md) for details on how to help make this documentation better.

---

*Last updated: 2025-08-10*
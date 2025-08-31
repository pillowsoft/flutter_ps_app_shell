#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../lib/src/doc_parser.dart';
import '../lib/src/llms_builder.dart';

/// Generate llms.txt files for Flutter App Shell documentation.
///
/// This CLI tool creates both /llms.txt (navigation index) and /llms-full.txt (complete content)
/// files following the official llms.txt specification from llmstxt.org.
///
/// Usage:
///   dart run generate_llms_txt.dart [options]
///
/// Options:
///   -d, --docs-dir      Directory containing documentation (default: docs)
///   -o, --output-dir    Output directory for generated files (default: .)
///   -v, --verbose       Enable verbose output
///   -h, --help          Show this help message

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'docs-dir',
      abbr: 'd',
      defaultsTo: 'docs',
      help: 'Directory containing documentation files',
    )
    ..addOption(
      'output-dir',
      abbr: 'o',
      defaultsTo: '.',
      help: 'Output directory for generated llms.txt files',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      help: 'Enable verbose output',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      defaultsTo: false,
      help: 'Show this help message',
    );

  late ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    print('Error parsing arguments: $e');
    print('');
    _showUsage(parser);
    exit(1);
  }

  if (results['help'] as bool) {
    _showUsage(parser);
    exit(0);
  }

  final docsDir = results['docs-dir'] as String;
  final outputDir = results['output-dir'] as String;
  final verbose = results['verbose'] as bool;

  try {
    await generateLLMsFiles(
      docsDirectory: docsDir,
      outputDirectory: outputDir,
      verbose: verbose,
    );
  } catch (e, stackTrace) {
    print('❌ Error generating llms.txt files: $e');
    if (verbose) {
      print('Stack trace:');
      print(stackTrace);
    }
    exit(1);
  }
}

/// Generate llms.txt files from documentation.
Future<void> generateLLMsFiles({
  required String docsDirectory,
  required String outputDirectory,
  required bool verbose,
}) async {
  if (verbose) {
    print('🚀 Generating llms.txt files for Flutter App Shell...');
    print('   📂 Docs directory: $docsDirectory');
    print('   📁 Output directory: $outputDirectory');
  }

  // Validate directories
  final docsDir = Directory(docsDirectory);
  if (!await docsDir.exists()) {
    throw Exception('Documentation directory does not exist: $docsDirectory');
  }

  final outputDir = Directory(outputDirectory);
  if (!await outputDir.exists()) {
    if (verbose) {
      print('   📁 Creating output directory: $outputDirectory');
    }
    await outputDir.create(recursive: true);
  }

  // Parse documentation files
  final parser = DocParser(
    docsDirectory: docsDir,
    verbose: verbose,
  );

  final docFiles = await parser.parseDocumentation();

  if (docFiles.isEmpty) {
    print('⚠️  No documentation files found in $docsDirectory');
    exit(1);
  }

  // Build llms.txt files
  final builder = LLMsBuilder(
    outputDirectory: outputDir,
    verbose: verbose,
  );

  await builder.buildLLMsFiles(docFiles);

  // Show completion summary
  print('✅ Successfully generated llms.txt files!');
  print('   📄 ${path.join(outputDirectory, 'llms.txt')} (navigation index)');
  print(
      '   📄 ${path.join(outputDirectory, 'llms-full.txt')} (complete content)');
  print('   📊 Processed ${docFiles.length} documentation files');

  if (verbose) {
    print('');
    print('📚 Processed files:');
    for (final doc in docFiles) {
      print('   ✓ ${doc.relativePath} (priority: ${doc.priority})');
    }
  }
}

/// Show usage information.
void _showUsage(ArgParser parser) {
  print('Generate llms.txt files for Flutter App Shell documentation.');
  print('');
  print('Usage: dart run generate_llms_txt.dart [options]');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Examples:');
  print('  # Generate in current directory');
  print('  dart run generate_llms_txt.dart');
  print('');
  print('  # Specify custom directories');
  print('  dart run generate_llms_txt.dart -d ../docs -o ../output');
  print('');
  print('  # Enable verbose output');
  print('  dart run generate_llms_txt.dart --verbose');
  print('');
  print(
      'The generated files follow the official llms.txt specification from llmstxt.org');
  print('and are optimized for large language model consumption.');
}

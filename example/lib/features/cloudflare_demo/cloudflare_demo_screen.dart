import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals/signals_flutter.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math' as math;

class CloudflareDemoScreen extends HookWidget {
  const CloudflareDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final cloudflare = getIt<CloudflareService>();
    final uploadResult = useState<String>('');
    final isUploading = useState(false);
    final aiResult = useState<String>('');
    final isGeneratingText = useState(false);
    final isGeneratingImage = useState(false);
    final generatedImageBytes = useState<Uint8List?>(null);
    final customApiResult = useState<String>('');
    final availableProviders = useState<CloudflareAIProviders?>(null);
    final selectedTextProvider = useState('workers-ai');
    final selectedTextModel = useState('@cf/meta/llama-3.1-8b-instruct');
    final selectedImageProvider = useState('workers-ai');
    final selectedImageModel =
        useState('@cf/stabilityai/stable-diffusion-xl-base-1.0');
    final maxTokens = useState(512);
    final temperature = useState(0.7);
    final enableCache = useState(true);
    final enableFallback = useState(false);
    final aiResultDetails = useState<CloudflareAIResult?>(null);
    final imageResultDetails = useState<CloudflareAIImageResult?>(null);
    final textPrompt = useTextEditingController(
        text: 'Write a haiku about Flutter development');
    final imagePrompt = useTextEditingController(
        text: 'A beautiful sunset over mountains, digital art style');

    // Load available providers when service is configured
    useEffect(() {
      if (cloudflare.isConfigured) {
        cloudflare.getAvailableProviders().then((providers) {
          availableProviders.value = providers;
        }).catchError((e) {
          print('Failed to load AI providers: $e');
        });
      }
      return null;
    }, [cloudflare.isConfigured]);

    // Local functions for analytics calculations
    String calculateCacheHitRate() {
      int total = 0;
      int cached = 0;

      if (aiResultDetails.value != null) {
        total++;
        if (aiResultDetails.value!.cached) cached++;
      }

      if (imageResultDetails.value != null) {
        total++;
        if (imageResultDetails.value!.cached) cached++;
      }

      if (total == 0) return '0%';
      return '${((cached / total) * 100).round()}%';
    }

    String calculateFallbackRate() {
      int total = 0;
      int fallbacks = 0;

      if (aiResultDetails.value != null) {
        total++;
        if (aiResultDetails.value!.usedFallback) fallbacks++;
      }

      if (imageResultDetails.value != null) {
        total++;
        if (imageResultDetails.value!.usedFallback) fallbacks++;
      }

      if (total == 0) return '0%';
      return '${((fallbacks / total) * 100).round()}%';
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ui.pageTitle('Cloudflare Integration'),

        const SizedBox(height: 16),

        // Service Status
        Watch((context) {
          final isConfigured = cloudflare.isConfigured;
          final status = cloudflare.connectionStatus.value;

          return ui.card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ui.text('Service Status',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ui.text('Configured: ${isConfigured ? 'Yes' : 'No'}'),
                  ui.text('Connection: ${status.name}'),
                  if (cloudflare.currentSession != null) ...[
                    const SizedBox(height: 8),
                    ui.text(
                        'Session active until: ${cloudflare.currentSession!.expiresAt.toLocal()}'),
                  ],
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // File Upload Section
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('File Upload',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ui.button(
                        onPressed: () {
                          if (isUploading.value) return;
                          () async {
                            final result =
                                await FilePicker.platform.pickFiles();
                            if (result != null) {
                              final file = result.files.first;
                              if (file.bytes != null) {
                                isUploading.value = true;
                                uploadResult.value =
                                    'Uploading ${file.name}...';

                                try {
                                  final upload = await cloudflare.uploadFile(
                                    bytes: file.bytes!,
                                    filename: file.name,
                                  );
                                  uploadResult.value =
                                      'Success!\nURL: ${upload.url}\nCDN: ${upload.cdnUrl ?? 'Not configured'}';
                                } catch (e) {
                                  uploadResult.value = 'Error: $e';
                                } finally {
                                  isUploading.value = false;
                                }
                              }
                            }
                          }();
                        },
                        child: const Text('Pick & Upload File'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ui.button(
                      onPressed: () {
                        if (isUploading.value) return;
                        () async {
                          // Generate sample data for testing
                          final sampleData = Uint8List.fromList(
                            List.generate(
                                1024 * 50, (i) => math.Random().nextInt(256)),
                          );

                          isUploading.value = true;
                          uploadResult.value = 'Uploading test file...';

                          try {
                            final upload = await cloudflare.uploadFile(
                              bytes: sampleData,
                              filename:
                                  'test_${DateTime.now().millisecondsSinceEpoch}.bin',
                            );
                            uploadResult.value =
                                'Success!\nURL: ${upload.url}\nCDN: ${upload.cdnUrl ?? 'Not configured'}';
                          } catch (e) {
                            uploadResult.value = 'Error: $e';
                          } finally {
                            isUploading.value = false;
                          }
                        }();
                      },
                      child: const Text('Upload Test File'),
                    ),
                  ],
                ),
                if (uploadResult.value.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ui.card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ui.text(
                        uploadResult.value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // AI Text Generation Section
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('AI Text Generation',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),

                // Provider Selection
                if (availableProviders.value != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ui.text('Provider',
                                style: Theme.of(context).textTheme.bodySmall),
                            DropdownButton<String>(
                              value: selectedTextProvider.value,
                              isExpanded: true,
                              items: availableProviders.value!.providers
                                  .where((p) => p.textModels.isNotEmpty)
                                  .map((provider) => DropdownMenuItem(
                                        value: provider.id,
                                        child: Row(
                                          children: [
                                            ui.text(provider.name),
                                            if (provider.requiresKey) ...[
                                              const SizedBox(width: 8),
                                              Icon(Icons.key,
                                                  size: 14,
                                                  color: Colors.orange),
                                            ],
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  selectedTextProvider.value = value;
                                  final provider = availableProviders.value!
                                      .getProvider(value);
                                  if (provider?.textModels.isNotEmpty == true) {
                                    selectedTextModel.value =
                                        provider!.textModels.first;
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ui.text('Model',
                                style: Theme.of(context).textTheme.bodySmall),
                            DropdownButton<String>(
                              value: selectedTextModel.value,
                              isExpanded: true,
                              items: availableProviders.value!
                                  .getTextModels(selectedTextProvider.value)
                                  .map((model) => DropdownMenuItem(
                                        value: model,
                                        child: ui.text(model,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  selectedTextModel.value = value;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Advanced Options
                  ExpansionTile(
                    title: ui.text('Advanced Options',
                        style: Theme.of(context).textTheme.bodyMedium),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ui.text('Max Tokens: ${maxTokens.value}'),
                                      Slider(
                                        value: maxTokens.value.toDouble(),
                                        min: 50,
                                        max: 2048,
                                        divisions: 20,
                                        onChanged: (value) {
                                          maxTokens.value = value.round();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ui.text(
                                          'Temperature: ${temperature.value.toStringAsFixed(1)}'),
                                      Slider(
                                        value: temperature.value,
                                        min: 0.0,
                                        max: 2.0,
                                        divisions: 20,
                                        onChanged: (value) {
                                          temperature.value = value;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title: ui.text('Enable Cache'),
                                    subtitle: ui.text('Faster repeat requests',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    value: enableCache.value,
                                    onChanged: (value) {
                                      if (value != null)
                                        enableCache.value = value;
                                    },
                                    dense: true,
                                  ),
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    title: ui.text('Enable Fallback'),
                                    subtitle: ui.text(
                                        'Try other providers if failed',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    value: enableFallback.value,
                                    onChanged: (value) {
                                      if (value != null)
                                        enableFallback.value = value;
                                    },
                                    dense: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                ui.textField(
                  controller: textPrompt,
                  label: 'Text Prompt',
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                ui.button(
                  onPressed: () {
                    if (isGeneratingText.value) return;
                    () async {
                      isGeneratingText.value = true;
                      aiResult.value = 'Generating...';
                      aiResultDetails.value = null;

                      try {
                        List<CloudflareAIFallback>? fallbacks;
                        if (enableFallback.value &&
                            availableProviders.value != null) {
                          // Create fallbacks from other providers
                          fallbacks = availableProviders.value!.providers
                              .where((p) =>
                                  p.id != selectedTextProvider.value &&
                                  p.textModels.isNotEmpty)
                              .take(2)
                              .map((p) => CloudflareAIFallback(
                                    provider: p.id,
                                    model: p.textModels.first,
                                  ))
                              .toList();
                        }

                        final result = await cloudflare.generateTextAdvanced(
                          prompt: textPrompt.text,
                          provider: selectedTextProvider.value,
                          model: selectedTextModel.value,
                          maxTokens: maxTokens.value,
                          temperature: temperature.value,
                          enableCache: enableCache.value,
                          fallbacks: fallbacks,
                        );

                        aiResult.value = result.response;
                        aiResultDetails.value = result;
                      } catch (e) {
                        aiResult.value = 'Error: $e';
                        aiResultDetails.value = null;
                      } finally {
                        isGeneratingText.value = false;
                      }
                    }();
                  },
                  child: const Text('Generate Text'),
                ),

                if (aiResult.value.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ui.card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (aiResultDetails.value != null) ...[
                            Row(
                              children: [
                                Icon(
                                  aiResultDetails.value!.cached
                                      ? Icons.cached
                                      : Icons.cloud,
                                  size: 16,
                                  color: aiResultDetails.value!.cached
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                ui.text(
                                  '${aiResultDetails.value!.provider}${aiResultDetails.value!.usedFallback ? ' (fallback)' : ''}${aiResultDetails.value!.cached ? ' • cached' : ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            aiResultDetails.value!.usedFallback
                                                ? Colors.orange
                                                : null,
                                      ),
                                ),
                                if (aiResultDetails.value!.usage != null) ...[
                                  const Spacer(),
                                  ui.text(
                                    '${aiResultDetails.value!.usage!['total_tokens'] ?? 'N/A'} tokens',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                            const Divider(),
                          ],
                          ui.text(aiResult.value),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // AI Image Generation Section
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('AI Image Generation',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),

                // Provider Selection for Images
                if (availableProviders.value != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ui.text('Provider',
                                style: Theme.of(context).textTheme.bodySmall),
                            DropdownButton<String>(
                              value: selectedImageProvider.value,
                              isExpanded: true,
                              items: availableProviders.value!.providers
                                  .where((p) => p.imageModels.isNotEmpty)
                                  .map((provider) => DropdownMenuItem(
                                        value: provider.id,
                                        child: Row(
                                          children: [
                                            ui.text(provider.name),
                                            if (provider.requiresKey) ...[
                                              const SizedBox(width: 8),
                                              Icon(Icons.key,
                                                  size: 14,
                                                  color: Colors.orange),
                                            ],
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  selectedImageProvider.value = value;
                                  final provider = availableProviders.value!
                                      .getProvider(value);
                                  if (provider?.imageModels.isNotEmpty ==
                                      true) {
                                    selectedImageModel.value =
                                        provider!.imageModels.first;
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ui.text('Model',
                                style: Theme.of(context).textTheme.bodySmall),
                            DropdownButton<String>(
                              value: selectedImageModel.value,
                              isExpanded: true,
                              items: availableProviders.value!
                                  .getImageModels(selectedImageProvider.value)
                                  .map((model) => DropdownMenuItem(
                                        value: model,
                                        child: ui.text(model,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  selectedImageModel.value = value;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                ui.textField(
                  controller: imagePrompt,
                  label: 'Image Prompt',
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                ui.button(
                  onPressed: () {
                    if (isGeneratingImage.value) return;
                    () async {
                      isGeneratingImage.value = true;
                      generatedImageBytes.value = null;
                      imageResultDetails.value = null;

                      try {
                        List<CloudflareAIFallback>? fallbacks;
                        if (enableFallback.value &&
                            availableProviders.value != null) {
                          // Create fallbacks from other image providers
                          fallbacks = availableProviders.value!.providers
                              .where((p) =>
                                  p.id != selectedImageProvider.value &&
                                  p.imageModels.isNotEmpty)
                              .take(2)
                              .map((p) => CloudflareAIFallback(
                                    provider: p.id,
                                    model: p.imageModels.first,
                                  ))
                              .toList();
                        }

                        final result = await cloudflare.generateImageAdvanced(
                          prompt: imagePrompt.text,
                          provider: selectedImageProvider.value,
                          model: selectedImageModel.value,
                          enableCache: enableCache.value,
                          fallbacks: fallbacks,
                        );

                        generatedImageBytes.value = result.imageBytes;
                        imageResultDetails.value = result;
                      } catch (e) {
                        ui.showSnackBar(context, 'Error generating image: $e');
                        imageResultDetails.value = null;
                      } finally {
                        isGeneratingImage.value = false;
                      }
                    }();
                  },
                  child: const Text('Generate Image'),
                ),

                if (generatedImageBytes.value != null) ...[
                  const SizedBox(height: 16),
                  if (imageResultDetails.value != null) ...[
                    Row(
                      children: [
                        Icon(
                          imageResultDetails.value!.cached
                              ? Icons.cached
                              : Icons.image,
                          size: 16,
                          color: imageResultDetails.value!.cached
                              ? Colors.green
                              : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        ui.text(
                          '${imageResultDetails.value!.provider}${imageResultDetails.value!.usedFallback ? ' (fallback)' : ''}${imageResultDetails.value!.cached ? ' • cached' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: imageResultDetails.value!.usedFallback
                                    ? Colors.orange
                                    : null,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: Image.memory(
                      generatedImageBytes.value!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Custom API Section
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Custom API Calls',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ui.button(
                        onPressed: () {
                          () async {
                            try {
                              final response =
                                  await cloudflare.callCustomEndpoint(
                                endpoint: '/health',
                                method: 'GET',
                              );
                              customApiResult.value = 'Health check: $response';
                            } catch (e) {
                              customApiResult.value = 'Error: $e';
                            }
                          }();
                        },
                        child: const Text('Health Check'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ui.button(
                        onPressed: () {
                          () async {
                            try {
                              final response =
                                  await cloudflare.callCustomEndpoint(
                                endpoint: '/v1/test',
                                method: 'POST',
                                data: {
                                  'message': 'Hello from Flutter!',
                                  'timestamp': DateTime.now().toIso8601String(),
                                },
                              );
                              customApiResult.value = 'API Response: $response';
                            } catch (e) {
                              customApiResult.value = 'Error: $e';
                            }
                          }();
                        },
                        child: const Text('Test API'),
                      ),
                    ),
                  ],
                ),
                if (customApiResult.value.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ui.card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ui.text(
                        customApiResult.value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // AI Gateway Analytics & Cost Tracking
        if (availableProviders.value != null) ...[
          ui.card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue),
                      const SizedBox(width: 8),
                      ui.text('AI Gateway Analytics',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Usage Statistics
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          context,
                          'Text Requests',
                          aiResultDetails.value != null ? '1' : '0',
                          Icons.text_fields,
                          aiResultDetails.value?.cached == true
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalyticsCard(
                          context,
                          'Image Requests',
                          imageResultDetails.value != null ? '1' : '0',
                          Icons.image,
                          imageResultDetails.value?.cached == true
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          context,
                          'Cache Hit Rate',
                          calculateCacheHitRate(),
                          Icons.cached,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnalyticsCard(
                          context,
                          'Fallback Rate',
                          calculateFallbackRate(),
                          Icons.backup,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Provider Performance
                  ExpansionTile(
                    title: ui.text('Provider Performance',
                        style: Theme.of(context).textTheme.bodyMedium),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (aiResultDetails.value != null) ...[
                              _buildProviderPerformanceRow(
                                context,
                                'Text Generation',
                                aiResultDetails.value!.provider,
                                aiResultDetails.value!.cached,
                                aiResultDetails.value!.usedFallback,
                                aiResultDetails.value!.usage,
                              ),
                            ],
                            if (imageResultDetails.value != null) ...[
                              const SizedBox(height: 8),
                              _buildProviderPerformanceRow(
                                context,
                                'Image Generation',
                                imageResultDetails.value!.provider,
                                imageResultDetails.value!.cached,
                                imageResultDetails.value!.usedFallback,
                                null,
                              ),
                            ],
                            if (aiResultDetails.value == null &&
                                imageResultDetails.value == null) ...[
                              ui.text(
                                'Generate some content to see performance metrics',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // AI Gateway Features
                  ui.card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ui.text('AI Gateway Benefits',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                          const SizedBox(height: 8),
                          _buildFeatureItem(
                              '✅ Multi-provider support (${availableProviders.value!.providers.length} providers)'),
                          _buildFeatureItem(
                              '✅ Automatic failover and retry logic'),
                          _buildFeatureItem(
                              '✅ Response caching for cost optimization'),
                          _buildFeatureItem(
                              '✅ Unified billing across all providers'),
                          _buildFeatureItem(
                              '✅ Enhanced security with DLP scanning'),
                          _buildFeatureItem(
                              '✅ Real-time analytics and monitoring'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Documentation Section
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Getting Started',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ui.text(
                  'To use Cloudflare features:\n\n'
                  '1. Copy worker templates: cp -r packages/flutter_app_shell/templates/cloudflare/* .\n'
                  '2. Setup: just setup-cloudflare\n'
                  '3. Configure secrets: just secrets-cloudflare\n'
                  '4. Deploy: just deploy-cloudflare\n\n'
                  'See docs/services/cloudflare.md for complete documentation.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final ui = getAdaptiveFactory(context);
    return ui.card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            ui.text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            ui.text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderPerformanceRow(
    BuildContext context,
    String type,
    String provider,
    bool cached,
    bool usedFallback,
    Map<String, dynamic>? usage,
  ) {
    final ui = getAdaptiveFactory(context);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ui.text(type, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              ui.text(provider, style: Theme.of(context).textTheme.bodySmall),
              if (usedFallback) ...[
                const SizedBox(width: 4),
                Icon(Icons.backup, size: 12, color: Colors.orange),
              ],
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Icon(
                cached ? Icons.cached : Icons.cloud,
                size: 12,
                color: cached ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              ui.text(
                cached ? 'Cached' : 'Live',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cached ? Colors.green : Colors.grey,
                    ),
              ),
            ],
          ),
        ),
        if (usage != null) ...[
          Expanded(
            child: ui.text(
              '${usage['total_tokens'] ?? 0}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ] else ...[
          const Expanded(child: SizedBox()),
        ],
      ],
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        feature,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

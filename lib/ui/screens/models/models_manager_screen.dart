import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_providers.dart';

class ModelsManagerScreen extends ConsumerWidget {
  const ModelsManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(modelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Model Manager',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('LOCAL INTELLIGENCE'),
          _buildGlassList(
            children: models
                .map(
                  (m) => ListTile(
                    leading: const Icon(Icons.memory, color: Color(0xFF8B5CF6)),
                    title: Text(
                      m.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${m.layerType} • ${m.sizeGB} GB'),
                    trailing: m.isDownloaded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : m.isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              value: m.progress,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.cloud_download_outlined,
                            color: Color(0xFF8B5CF6),
                          ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('INFERENCE ENGINE'),
          _buildGlassList(
            children: [
              SwitchListTile(
                title: const Text(
                  'Hardware Acceleration (NPU)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: ref.watch(hardwareAccelerationProvider),
                activeThumbColor: const Color(0xFF8B5CF6),
                onChanged: (v) =>
                    ref.read(hardwareAccelerationProvider.notifier).setToggle(v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text(
                  'Aggressive RAM Unloading',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: ref.watch(aggressiveRamUnloadingProvider),
                activeThumbColor: const Color(0xFF8B5CF6),
                onChanged: (v) => ref
                    .read(aggressiveRamUnloadingProvider.notifier)
                    .setToggle(v),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('SYSTEM'),
          _buildGlassList(
            children: const [
              ListTile(
                leading: Icon(Icons.folder_open),
                title: Text(
                  'Manage Local Storage',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Icon(Icons.chevron_right),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.security),
                title: Text(
                  'Privacy & Telemetry',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildGlassList({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            border: Border.all(color: Colors.white),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}
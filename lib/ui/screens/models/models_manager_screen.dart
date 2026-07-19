import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_providers.dart';
import '../../core/theme.dart';

class ModelsManagerScreen extends ConsumerWidget {
  const ModelsManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(modelsProvider);

    return Scaffold(
      backgroundColor: EdgeXTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: EdgeXTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Model Manager',
          style: TextStyle(fontWeight: FontWeight.w900, color: EdgeXTheme.textPrimary),
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
                    leading: const Icon(Icons.memory, color: EdgeXTheme.cyanAccent),
                    title: Text(
                      m.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: EdgeXTheme.textPrimary),
                    ),
                    subtitle: Text('${m.layerType} • ${m.sizeGB} GB', style: const TextStyle(color: EdgeXTheme.textSecondary)),
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
                            color: EdgeXTheme.cyanAccent,
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
                  style: TextStyle(fontWeight: FontWeight.w600, color: EdgeXTheme.textPrimary),
                ),
                value: ref.watch(hardwareAccelerationProvider),
                activeThumbColor: EdgeXTheme.cyanAccent,
                activeTrackColor: EdgeXTheme.cyanAccent.withValues(alpha: 0.3),
                inactiveThumbColor: EdgeXTheme.textSecondary,
                inactiveTrackColor: EdgeXTheme.surfaceHighlight,
                onChanged: (v) =>
                    ref.read(hardwareAccelerationProvider.notifier).setToggle(v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text(
                  'Aggressive RAM Unloading',
                  style: TextStyle(fontWeight: FontWeight.w600, color: EdgeXTheme.textPrimary),
                ),
                value: ref.watch(aggressiveRamUnloadingProvider),
                activeThumbColor: EdgeXTheme.cyanAccent,
                activeTrackColor: EdgeXTheme.cyanAccent.withValues(alpha: 0.3),
                inactiveThumbColor: EdgeXTheme.textSecondary,
                inactiveTrackColor: EdgeXTheme.surfaceHighlight,
                onChanged: (v) => ref
                    .read(aggressiveRamUnloadingProvider.notifier)
                    .setToggle(v),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('SYSTEM'),
          _buildGlassList(
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open, color: EdgeXTheme.textPrimary),
                title: const Text(
                  'Manage Local Storage',
                  style: TextStyle(fontWeight: FontWeight.w600, color: EdgeXTheme.textPrimary),
                ),
                trailing: const Icon(Icons.chevron_right, color: EdgeXTheme.textSecondary),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security, color: EdgeXTheme.textPrimary),
                title: const Text(
                  'Privacy & Telemetry',
                  style: TextStyle(fontWeight: FontWeight.w600, color: EdgeXTheme.textPrimary),
                ),
                trailing: const Icon(Icons.chevron_right, color: EdgeXTheme.textSecondary),
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
          color: EdgeXTheme.textSecondary,
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
            color: EdgeXTheme.surface,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/state/app_providers.dart';
import '../../core/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(modelsProvider);
    final hasNPU = ref.watch(hardwareAccelerationProvider);
    final aggRam = ref.watch(aggressiveRamUnloadingProvider);
    final hw = ref.watch(hardwareInfoProvider);

    return Scaffold(
      backgroundColor: EdgeXTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: EdgeXTheme.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: EdgeXTheme.textPrimary),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: EdgeXTheme.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('NATIVE HARDWARE PROFILE'),
                  _SettingsGroup(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: EdgeXTheme.textPrimary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: hw.isDetecting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: EdgeXTheme.cyanAccent,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.smartphone,
                                      color: EdgeXTheme.textPrimary,
                                      size: 28,
                                    ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hw.deviceName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: EdgeXTheme.textPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${hw.cpuArchitecture}\n${hw.totalRamGB.toStringAsFixed(1)} GB Total RAM',
                                    style: const TextStyle(
                                      color: EdgeXTheme.textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader('LOCAL MODELS (GGUF)'),
                  _SettingsGroup(
                    children: models.asMap().entries.map((entry) {
                      final isLast = entry.key == models.length - 1;
                      return Column(
                        children: [
                          _buildModelTile(entry.value, ref, context, hw),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: Colors.white10,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader('INFERENCE PIPELINE'),
                  _SettingsGroup(
                    children: [
                      _buildToggleTile(
                        Icons.memory,
                        'GPU Acceleration (Metal/Vulkan)',
                        hasNPU,
                        EdgeXTheme.cyanAccent,
                        (v) {
                          HapticFeedback.selectionClick();
                          ref
                              .read(hardwareAccelerationProvider.notifier)
                              .setToggle(v);
                          _showToast(
                            context,
                            v
                                ? 'GPU Pipeline Activated'
                                : 'Switched to CPU Fallback',
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 64),
                      _buildToggleTile(
                        Icons.speed,
                        'Aggressive RAM Unload',
                        aggRam,
                        Colors.orange,
                        (v) {
                          HapticFeedback.selectionClick();
                          ref
                              .read(aggressiveRamUnloadingProvider.notifier)
                              .setToggle(v);
                          _showToast(
                            context,
                            v
                                ? 'Strict Memory Limits Enforced'
                                : 'Standard Memory Mode Restored',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader('SYSTEM'),
                  _SettingsGroup(
                    children: [
                      _buildNavigationTile(
                        Icons.folder_open,
                        'Manage Local Storage',
                        Colors.blue,
                        () => _showStorageModal(context, ref),
                      ),
                      const Divider(height: 1, indent: 64),
                      _buildNavigationTile(
                        Icons.security,
                        'Privacy & Telemetry',
                        Colors.green,
                        () => _showPrivacyModal(context, ref),
                      ),
                    ],
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: EdgeXTheme.textSecondary,
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _buildModelTile(
    AIModel model,
    WidgetRef ref,
    BuildContext context,
    DeviceHardware hw,
  ) {
    final isCompatible = hw.totalRamGB >= model.requiredRamGB;
    final isActive =
        ref.watch(selectedModelProvider) == model.title && model.isDownloaded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : EdgeXTheme.cyanAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.hub_outlined,
              color: isActive
                  ? const Color(0xFF10B981)
                  : EdgeXTheme.cyanAccent,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        model.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: EdgeXTheme.textPrimary,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${model.layerType} • ${model.sizeGB} GB',
                  style: const TextStyle(
                    color: EdgeXTheme.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  model.description,
                  style: const TextStyle(
                    color: EdgeXTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (model.isDownloading || model.isPaused) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: model.progress,
                      backgroundColor: EdgeXTheme.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        model.isPaused
                            ? const Color(0xFFF59E0B)
                            : EdgeXTheme.cyanAccent,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    model.isPaused
                        ? 'Paused • ${(model.progress * 100).toStringAsFixed(1)}%'
                        : 'Downloading... ${(model.progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: model.isPaused
                          ? const Color(0xFFF59E0B)
                          : EdgeXTheme.cyanAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildModelTrailingAction(model, ref, context, isCompatible, isActive),
        ],
      ),
    );
  }

  Widget _buildModelTrailingAction(
    AIModel model,
    WidgetRef ref,
    BuildContext context,
    bool isCompatible,
    bool isActive,
  ) {
    if (model.isDownloaded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isActive)
            IconButton(
              icon: const Icon(
                Icons.radio_button_unchecked,
                color: EdgeXTheme.textSecondary,
                size: 24,
              ),
              tooltip: 'Set Active',
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(selectedModelProvider.notifier).setModel(model.title);
                _showToast(context, '${model.title} Activated');
              },
            ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFEF4444),
              size: 24,
            ),
            tooltip: 'Delete Model',
            onPressed: () {
              HapticFeedback.heavyImpact();
              ref.read(modelsProvider.notifier).deleteModel(model.title);
              _showToast(context, '${model.title} Deleted');
            },
          ),
        ],
      );
    } else if (model.isPaused) {
      return IconButton(
        icon: const Icon(
          Icons.play_circle_fill,
          color: EdgeXTheme.cyanAccent,
          size: 36,
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          ref.read(modelsProvider.notifier).resumeDownload(model.title);
        },
      );
    } else if (model.isDownloading) {
      return IconButton(
        icon: const Icon(
          Icons.pause_circle_filled,
          color: Color(0xFFF59E0B),
          size: 36,
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          ref.read(modelsProvider.notifier).pauseDownload(model.title);
        },
      );
    } else if (!isCompatible) {
      return Column(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(height: 4),
          Text(
            'REQ\n${model.requiredRamGB}GB\nRAM',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    } else {
      return IconButton(
        icon: const Icon(
          Icons.cloud_download_outlined,
          color: EdgeXTheme.cyanAccent,
          size: 30,
        ),
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final started = await ref
              .read(modelsProvider.notifier)
              .downloadModel(model.title);
          if (!started && context.mounted) {
            _showToast(
              context,
              'Storage Limit: Max 3 models. Please delete one first.',
            );
          }
        },
      );
    }
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    bool value,
    Color iconColor,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: EdgeXTheme.textPrimary,
          fontSize: 15,
        ),
      ),
      value: value,
      activeThumbColor: EdgeXTheme.cyanAccent,
      activeTrackColor: EdgeXTheme.cyanAccent.withValues(alpha: 0.25),
      onChanged: onChanged,
    );
  }

  Widget _buildNavigationTile(
    IconData icon,
    String title,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: EdgeXTheme.textPrimary,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: EdgeXTheme.textSecondary),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }

  void _showStorageModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final storage = ref.watch(storageProvider);
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: EdgeXTheme.textSecondary.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'EdgeX Storage',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _StorageBar(
                        label: 'Total App Size',
                        value: '${storage.totalAppSizeGB.toStringAsFixed(2)} GB',
                        color: EdgeXTheme.textPrimary,
                      ),
                      const SizedBox(height: 16),
                      _StorageBar(
                        label: 'Downloaded AI Models',
                        value:
                            '${storage.modelsSizeGB.toStringAsFixed(2)} GB',
                        color: EdgeXTheme.cyanAccent,
                      ),
                      const SizedBox(height: 16),
                      _StorageBar(
                        label: 'Temporary Cache',
                        value:
                            '${storage.cacheSizeGB.toStringAsFixed(2)} GB',
                        color: EdgeXTheme.textSecondary,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text(
                            'Clear Temporary Cache',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: storage.cacheSizeGB > 0
                              ? () {
                                  HapticFeedback.heavyImpact();
                                  ref
                                      .read(storageProvider.notifier)
                                      .clearCache();
                                  _showToast(context, 'Cache Cleared');
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPrivacyModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final privacy = ref.watch(privacySettingsProvider);
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: EdgeXTheme.textSecondary.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Privacy & Telemetry',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'EdgeX runs 100% locally. Manage what hardware metadata leaves your device.',
                        style: TextStyle(
                          color: EdgeXTheme.textSecondary,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SwitchListTile(
                        title: const Text(
                          'Share Hardware Telemetry',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        value: privacy['telemetry']!,
                        activeThumbColor: EdgeXTheme.cyanAccent,
                        activeTrackColor: EdgeXTheme.cyanAccent.withValues(alpha: 0.25),
                        onChanged: (_) => ref
                            .read(privacySettingsProvider.notifier)
                            .toggle('telemetry'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'Share Crash Reports',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        value: privacy['crash_reports']!,
                        activeThumbColor: EdgeXTheme.cyanAccent,
                        activeTrackColor: EdgeXTheme.cyanAccent.withValues(alpha: 0.25),
                        onChanged: (_) => ref
                            .read(privacySettingsProvider.notifier)
                            .toggle('crash_reports'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: EdgeXTheme.surfaceHighlight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _StorageBar extends StatelessWidget {
  final String label, value;
  final Color color;

  const _StorageBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: EdgeXTheme.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: EdgeXTheme.textPrimary,
          fontSize: 16,
        ),
      ),
    ],
  );
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: EdgeXTheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(children: children),
  );
}
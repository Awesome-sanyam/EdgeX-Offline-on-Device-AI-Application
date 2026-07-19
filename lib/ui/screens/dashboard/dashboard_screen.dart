import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/state/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(telemetryStreamProvider);
    final hw = ref.watch(hardwareInfoProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar.large(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'System Overview',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 32,
                color: Color(0xFF0F172A),
                letterSpacing: -1.0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('LIVE TELEMETRY'),
                  if (hw.isDetecting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    )
                  else
                    telemetryAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      error: (err, _) => Text(
                        'Telemetry Error: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                      data: (telemetry) =>
                          _buildLiveHardwareGrid(telemetry, hw),
                    ),
                  const SizedBox(height: 48),
                  _buildSectionHeader('ACTIVE ENGINE STATUS'),
                  _buildEngineStatusCard(ref, hw),
                  const SizedBox(height: 48),
                  _buildSectionHeader('RECENT TASKS'),
                  _buildRecentTasks(ref),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 16),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _buildLiveHardwareGrid(HardwareTelemetry telemetry, DeviceHardware hw) {
    final ramUsageGB = telemetry.ramUsageMB / 1024;
    final ramPercentage =
        hw.totalRamGB > 0 ? (ramUsageGB / hw.totalRamGB).clamp(0.0, 1.0) : 0.0;
    final gpuPercentage = (telemetry.gpuUsage / 100).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: _GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.memory, size: 14, color: Color(0xFF64748B)),
                    SizedBox(width: 6),
                    Text(
                      'ACTIVE RAM',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${ramUsageGB.toStringAsFixed(1)} GB',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '/ ${hw.totalRamGB.toStringAsFixed(1)} GB total',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                // BUG FIX: Use LayoutBuilder instead of MediaQuery * 0.4
                _ProgressBar(value: ramPercentage, color: const Color(0xFF8B5CF6)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.developer_board,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'GPU COMPUTE',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      telemetry.gpuUsage.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3, left: 2),
                      child: Text(
                        '%',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${telemetry.thermalTempC.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: telemetry.thermalTempC > 40
                        ? Colors.orange
                        : const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _ProgressBar(
                  value: gpuPercentage,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEngineStatusCard(WidgetRef ref, DeviceHardware hw) {
    final hasGPUAccel = ref.watch(hardwareAccelerationProvider);

    return _GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStatRow('DEVICE', hw.deviceName, false, const Color(0xFF0F172A)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFE2E8F0), height: 1),
          ),
          _buildStatRow(
            'SILICON',
            hw.cpuArchitecture,
            false,
            const Color(0xFF0F172A),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFE2E8F0), height: 1),
          ),
          _buildStatRow(
            'PIPELINE',
            hasGPUAccel ? 'GPU Acceleration (Active)' : 'CPU Fallback',
            hasGPUAccel,
            hasGPUAccel ? const Color(0xFF10B981) : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    bool hasIcon,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasIcon) ...[
                Icon(Icons.bolt, size: 14, color: valueColor),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTasks(WidgetRef ref) {
    final tasks = ref.watch(recentTasksProvider);
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'No activity yet.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Column(
      children: tasks
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        t.isDoc ? Icons.description : Icons.chat_bubble,
                        color: const Color(0xFF8B5CF6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        t.title,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Text(
                      'JUST NOW',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    // BUG FIX: Use LayoutBuilder so the bar fills its parent width correctly
    // on all screen sizes. The old approach used MediaQuery * 0.4 which was
    // always wrong on large and small screens.
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * value,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
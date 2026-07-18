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
            title: Text('System Overview', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Color(0xFF0F172A), letterSpacing: -1.0)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('LIVE TELEMETRY'),
                  // LAUNCH POLISH: Wait for real hardware detection to finish
                  if (hw.isDetecting)
                    const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: Color(0xFF8B5CF6))))
                  else
                    telemetryAsync.when(
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))),
                      error: (err, stack) => Text('Telemetry Error: $err', style: const TextStyle(color: Colors.red)),
                      data: (telemetry) => _buildLiveHardwareGrid(telemetry, hw), 
                    ),
                  const SizedBox(height: 48),
                  
                  _buildSectionHeader('ACTIVE ENGINE STATUS'),
                  _buildEngineStatusCard(ref, hw),
                  const SizedBox(height: 48),
                  
                  _buildSectionHeader('RECENT TASKS'),
                  _buildRecentTasks(ref),
                  const SizedBox(height: 100), 
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 16), 
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.5))
  );

  Widget _buildLiveHardwareGrid(HardwareTelemetry telemetry, DeviceHardware hw) {
    final ramUsageGB = telemetry.ramUsageMB / 1024;
    final ramPercentage = hw.totalRamGB > 0 ? (ramUsageGB / hw.totalRamGB).clamp(0.0, 1.0) : 0.0;
    final gpuPercentage = (telemetry.gpuUsage / 100).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: _GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.memory, size: 16, color: Color(0xFF64748B)), SizedBox(width: 8), Text('ACTIVE RAM', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 20),
                Text('${ramUsageGB.toStringAsFixed(1)} GB', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                Text('/ ${hw.totalRamGB.toStringAsFixed(1)} GB', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
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
                // FIX: Changed label to GPU COMPUTE
                const Row(children: [Icon(Icons.developer_board, size: 16, color: Color(0xFF64748B)), SizedBox(width: 8), Text('GPU COMPUTE', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // FIX: Pointing to the real calculated GPU Usage
                    Text(telemetry.gpuUsage.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const Padding(padding: EdgeInsets.only(bottom: 4, left: 2), child: Text('%', style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w800))),
                  ],
                ),
                Text('${telemetry.thermalTempC.toStringAsFixed(1)}°C', style: TextStyle(color: telemetry.thermalTempC > 40 ? Colors.orange : const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                _ProgressBar(value: gpuPercentage, color: const Color(0xFF10B981)), 
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
          _buildStatRow('DEVICE', hw.deviceName, false, Colors.black),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(color: Colors.white)),
          _buildStatRow('SILICON', hw.cpuArchitecture, false, Colors.black),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(color: Colors.white)),
          // FIX: Reflects GPU Acceleration accurately
          _buildStatRow('PIPELINE', hasGPUAccel ? 'GPU Acceleration (Active)' : 'CPU Fallback', hasGPUAccel, hasGPUAccel ? const Color(0xFF10B981) : Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool hasIcon, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)), 
        Row(
          children: [
            if (hasIcon) Icon(Icons.bolt, size: 16, color: valueColor), 
            if (hasIcon) const SizedBox(width: 4), 
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: valueColor, fontSize: 15))
          ]
        )
      ]
    );
  }

  Widget _buildRecentTasks(WidgetRef ref) {
    final tasks = ref.watch(recentTasksProvider);
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0), 
        child: Text('No activity yet.', style: TextStyle(color: Color(0xFF94A3B8)))
      );
    }
    
    return Column(
      children: tasks.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), 
                // FIX: Updated withValues instead of withOpacity
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), 
                child: Icon(t.isDoc ? Icons.description : Icons.chat_bubble, color: const Color(0xFF8B5CF6), size: 22)
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(t.title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 15))),
              const Text('JUST NOW', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800)), 
            ],
          ),
        ),
      )).toList(),
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
      borderRadius: BorderRadius.circular(32), 
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), 
        child: Container(
          padding: padding, 
          decoration: BoxDecoration(
            // FIX: Updated withValues instead of withOpacity
            color: Colors.white.withValues(alpha: 0.6), 
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5), 
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 12))
            ]
          ), 
          child: child
        )
      )
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value; 
  final Color color;
  
  const _ProgressBar({required this.value, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8, 
      width: double.infinity, 
      // FIX: Updated withValues instead of withOpacity
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)), 
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800), 
            curve: Curves.easeOutCubic, 
            width: MediaQuery.of(context).size.width * value * 0.4, 
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))
          )
        ]
      )
    );
  }
}
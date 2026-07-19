import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/state/chat_stream_provider.dart';
import '../../../../core/state/ai_state_provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/surface_card.dart';

class StreamingMessageBubble extends ConsumerWidget {
  const StreamingMessageBubble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamText = ref.watch(activeStreamProvider);

    final displayText = streamText.isEmpty
        ? "Here is the optimized script:\n\ndef sort_data(data):\n    return sorted(data)"
        : streamText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: EdgeXTheme.cyanAccent,
          radius: 16,
          child: Icon(LucideIcons.sparkles, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayText,
                  style: const TextStyle(color: EdgeXTheme.textPrimary, height: 1.5),
                ),
                const SizedBox(height: 16),
                const _InferenceTelemetryBadge(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InferenceTelemetryBadge extends ConsumerWidget {
  const _InferenceTelemetryBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(aiStateProvider.select((s) => s.inferenceSpeedTs));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: EdgeXTheme.cyanAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: EdgeXTheme.cyanAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.zap, size: 12, color: EdgeXTheme.cyanAccent),
              const SizedBox(width: 4),
              Text(
                '$speed t/s',
                style: const TextStyle(color: EdgeXTheme.cyanAccent, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

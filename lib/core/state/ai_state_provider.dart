import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_state.dart';

class AIStateNotifier extends Notifier<AIState> {
  @override
  AIState build() {
    return const AIState(
      activeLayer: AILayer.micro,
      modelName: 'Llama-3-Nano-Q4.gguf',
      ramUsageMB: 850,
      temperatureCelsius: 38.0,
      inferenceSpeedTs: 42,
    );
  }

  void updateTelemetry({double? ramMB, double? tempC, int? speedTs}) {
    state = state.copyWith(
      ramUsageMB: ramMB,
      temperatureCelsius: tempC,
      inferenceSpeedTs: speedTs,
    );
  }

  void switchModel(AILayer layer, String name) {
    state = state.copyWith(activeLayer: layer, modelName: name);
  }
}

final aiStateProvider = NotifierProvider<AIStateNotifier, AIState>(() {
  return AIStateNotifier();
});

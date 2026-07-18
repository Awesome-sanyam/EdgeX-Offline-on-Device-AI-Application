enum AILayer { nano, micro, standard, macro, vision, none }

class AIState {
  final AILayer activeLayer;
  final String modelName;
  final double ramUsageMB;
  final double temperatureCelsius;
  final int inferenceSpeedTs;

  const AIState({
    this.activeLayer = AILayer.none,
    this.modelName = 'Disconnected',
    this.ramUsageMB = 0.0,
    this.temperatureCelsius = 0.0,
    this.inferenceSpeedTs = 0,
  });

  AIState copyWith({
    AILayer? activeLayer,
    String? modelName,
    double? ramUsageMB,
    double? temperatureCelsius,
    int? inferenceSpeedTs,
  }) {
    return AIState(
      activeLayer: activeLayer ?? this.activeLayer,
      modelName: modelName ?? this.modelName,
      ramUsageMB: ramUsageMB ?? this.ramUsageMB,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      inferenceSpeedTs: inferenceSpeedTs ?? this.inferenceSpeedTs,
    );
  }
}

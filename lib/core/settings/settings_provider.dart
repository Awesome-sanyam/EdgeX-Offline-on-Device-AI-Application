import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/local_db.dart';
import '../hardware/hardware_provider.dart';

// --- PERSISTENT SETTINGS & PRIVACY ---

class HardwareAccelerationNotifier extends Notifier<bool> {
  @override
  bool build() {
    return localDb.getBool('npu_enabled') ??
        ref.watch(hardwareInfoProvider).hasNeuralEngine;
  }

  void setToggle(bool value) {
    state = value;
    localDb.setBool('npu_enabled', value);
  }
}

final hardwareAccelerationProvider =
    NotifierProvider<HardwareAccelerationNotifier, bool>(
      () => HardwareAccelerationNotifier(),
    );

class AggressiveRamNotifier extends Notifier<bool> {
  @override
  bool build() => localDb.getBool('agg_ram') ?? false;

  void setToggle(bool value) {
    state = value;
    localDb.setBool('agg_ram', value);
  }
}

final aggressiveRamUnloadingProvider =
    NotifierProvider<AggressiveRamNotifier, bool>(
      () => AggressiveRamNotifier(),
    );

class PrivacySettingsNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    final saved = localDb.getString('privacy_settings');
    if (saved != null) return Map<String, bool>.from(jsonDecode(saved));
    return {'telemetry': false, 'crash_reports': true, 'local_logs': true};
  }

  void toggle(String key) {
    state = {...state, key: !state[key]!};
    localDb.setString('privacy_settings', jsonEncode(state));
  }
}

final privacySettingsProvider =
    NotifierProvider<PrivacySettingsNotifier, Map<String, bool>>(
      () => PrivacySettingsNotifier(),
    );



import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceCapabilityService {
  // Mock implementations for Phase 2. Will bridge to MethodChannels/FFI in Phase 3.
  Future<int> getTotalRamGB() async => 8;
  Future<int> getAvailableRamMB() async => 4096;
  Future<int> getCpuCoreCount() async => 8;

  // 0 = Normal, 1 = Light, 2 = Moderate, 3 = Severe, 4 = Critical
  Future<int> getThermalStatus() async => 0;

  bool canLoadMacroModel(int availableRamMB, int thermalStatus) {
    return availableRamMB > 3000 && thermalStatus < 2;
  }
}

final deviceServiceProvider = Provider<DeviceCapabilityService>((ref) {
  return DeviceCapabilityService();
});

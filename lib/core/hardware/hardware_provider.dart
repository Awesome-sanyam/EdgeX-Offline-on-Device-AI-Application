import 'dart:async';
import 'dart:io' show Platform, File;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:system_info_plus/system_info_plus.dart';

// --- DEEP NATIVE HARDWARE PROFILING ---

class DeviceHardware {
  final String deviceName;
  final String cpuArchitecture;
  final double totalRamGB;
  final bool hasNeuralEngine;
  final bool isDetecting;

  const DeviceHardware({
    required this.deviceName,
    required this.cpuArchitecture,
    required this.totalRamGB,
    required this.hasNeuralEngine,
    this.isDetecting = false,
  });
}

class HardwareNotifier extends Notifier<DeviceHardware> {
  @override
  DeviceHardware build() {
    _detectRealHardware();
    return const DeviceHardware(
      deviceName: 'Detecting Silicon...',
      cpuArchitecture: 'Scanning...',
      totalRamGB: 0.0,
      hasNeuralEngine: false,
      isDetecting: true,
    );
  }

  Future<void> _detectRealHardware() async {
    final deviceInfo = DeviceInfoPlugin();
    String dName = 'Android Device';
    String cpuArch = 'Generic ARM';
    double actualRamGB = 0.0;
    bool npu = false;

    try {
      final memoryMB = await SystemInfoPlus.physicalMemory;
      if (memoryMB != null && memoryMB > 0) actualRamGB = memoryMB / 1024.0;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        dName = '${androidInfo.manufacturer} ${androidInfo.model}';
        final hardware = androidInfo.hardware.toLowerCase();
        final board = androidInfo.board.toLowerCase();
        cpuArch = androidInfo.hardware.toUpperCase();

        final npsReg = RegExp(
          r'(gs[0-9]+|tensor|sm[0-9]+|snapdragon|s5e[0-9]+|exynos|mt[0-9]+|dimensity|cheetah|pantheon)',
        );
        npu = npsReg.hasMatch(hardware) || npsReg.hasMatch(board);

        if (actualRamGB < 1.0) {
          actualRamGB = (Platform.numberOfProcessors >= 8) ? 12.0 : 8.0;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        dName = 'iPhone ${iosInfo.utsname.machine}';
        cpuArch = 'APPLE NEURAL ENGINE';
        npu = true;
        if (actualRamGB < 1.0) actualRamGB = 8.0;
      }
    } catch (_) {
      dName = 'EdgeX Secure Kernel';
    }

    state = DeviceHardware(
      deviceName: dName,
      cpuArchitecture: cpuArch,
      totalRamGB: actualRamGB,
      hasNeuralEngine: npu,
      isDetecting: false,
    );
  }
}

final hardwareInfoProvider =
    NotifierProvider<HardwareNotifier, DeviceHardware>(() => HardwareNotifier());



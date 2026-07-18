import 'dart:ffi';
import 'dart:io';

class AIEngineBridge {
  static final AIEngineBridge _instance = AIEngineBridge._internal();
  late final DynamicLibrary _lib;

  factory AIEngineBridge() {
    return _instance;
  }

  AIEngineBridge._internal() {
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libcore_ai_engine.so');
    } else {
      throw UnsupportedError('This platform is not yet supported for edge AI.');
    }
  }

  // Bind the C++ function to Dart
  late final int Function() initializeEngine = _lib
      .lookup<NativeFunction<Int32 Function()>>('initialize_ai_engine')
      .asFunction();
}

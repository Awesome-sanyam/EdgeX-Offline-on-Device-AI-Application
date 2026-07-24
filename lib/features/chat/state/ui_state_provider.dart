import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/db/local_db.dart';
import '../../../core/state/tasks_provider.dart';
import 'chat_provider.dart';

// --- UI STATE PROVIDERS ---

class SelectedModelNotifier extends Notifier<String> {
  @override
  String build() =>
      localDb.getString('selected_model') ?? 'Qwen 2.5 Fast';

  void setModel(String model) {
    state = model;
    localDb.setString('selected_model', model);
  }
}

final selectedModelProvider =
    NotifierProvider<SelectedModelNotifier, String>(
      () => SelectedModelNotifier(),
    );

class ChatAttachmentNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setAttachment(String? filePath) => state = filePath;
}

final chatAttachmentProvider =
    NotifierProvider<ChatAttachmentNotifier, String?>(
      () => ChatAttachmentNotifier(),
    );

class VisionMediaNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setMedia(String? fileName) {
    state = fileName;
    if (fileName != null) {
      ref.read(recentTasksProvider.notifier).addTask('Vision Analysis', false);
    }
  }
}

final visionMediaProvider =
    NotifierProvider<VisionMediaNotifier, String?>(() => VisionMediaNotifier());

class StorageState {
  final double totalAppSizeGB;
  final double modelsSizeGB;
  final double cacheSizeGB;

  const StorageState(this.totalAppSizeGB, this.modelsSizeGB, this.cacheSizeGB);
}

class StorageNotifier extends AsyncNotifier<StorageState> {
  @override
  Future<StorageState> build() async => _compute();

  Future<StorageState> _compute() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final allFiles = dir.listSync();

      double modelBytes = 0;
      double otherBytes = 0;

      for (final f in allFiles) {
        if (f is File) {
          final size = f.lengthSync().toDouble();
          final name = f.path.toLowerCase();
          if (name.endsWith('.gguf') || name.endsWith('.bin')) {
            modelBytes += size;
          } else {
            otherBytes += size;
          }
        }
      }

      const double gb = 1024 * 1024 * 1024;
      return StorageState(
        (modelBytes + otherBytes) / gb,
        modelBytes / gb,
        otherBytes / gb,
      );
    } catch (_) {
      return const StorageState(0, 0, 0);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _compute());
  }

  Future<void> clearCache() async {
    ref.read(chatProvider.notifier).clearHistory();
    state = await AsyncValue.guard(_compute);
  }
}

final storageProvider =
    AsyncNotifierProvider<StorageNotifier, StorageState>(() => StorageNotifier());



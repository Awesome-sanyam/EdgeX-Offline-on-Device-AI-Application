import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class StorageNotifier extends Notifier<StorageState> {
  @override
  StorageState build() => const StorageState(1.5, 0.35, 1.2);

  void clearCache() {
    state = StorageState(
      state.totalAppSizeGB - state.cacheSizeGB,
      state.modelsSizeGB,
      0.0,
    );
    ref.read(chatProvider.notifier).clearHistory();
  }
}

final storageProvider =
    NotifierProvider<StorageNotifier, StorageState>(() => StorageNotifier());



import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../features/chat/state/ui_state_provider.dart';

// --- NATIVE BACKGROUND MODELS DOWNLOADER ---

class AIModel {
  final String title;
  final String layerType;
  final String description;
  final double progress;
  final double sizeGB;
  final double requiredRamGB;
  final bool isDownloading;
  final bool isDownloaded;
  final bool isPaused;
  final String downloadUrl;
  final String fileName;

  const AIModel({
    required this.title,
    required this.layerType,
    required this.description,
    required this.progress,
    required this.sizeGB,
    required this.requiredRamGB,
    this.isDownloading = false,
    this.isDownloaded = false,
    this.isPaused = false,
    required this.downloadUrl,
    required this.fileName,
  });

  AIModel copyWith({
    double? progress,
    bool? isDownloading,
    bool? isDownloaded,
    bool? isPaused,
  }) => AIModel(
    title: title,
    layerType: layerType,
    description: description,
    sizeGB: sizeGB,
    requiredRamGB: requiredRamGB,
    downloadUrl: downloadUrl,
    fileName: fileName,
    progress: progress ?? this.progress,
    isDownloading: isDownloading ?? this.isDownloading,
    isDownloaded: isDownloaded ?? this.isDownloaded,
    isPaused: isPaused ?? this.isPaused,
  );
}

class ModelsNotifier extends Notifier<List<AIModel>> {
  // BUG FIX: Single managed subscription — prevents duplicate listeners on
  // resume that caused the dual-percentage flicker.
  StreamSubscription<TaskUpdate>? _updateSubscription;

  static const List<AIModel> _catalog = [
    AIModel(
      title: 'Qwen 2.5 Fast',
      layerType: 'High Speed (1.5B)',
      description:
          'Blazing fast responses. Best for simple questions, brainstorming, and daily chat. Very low battery drain.',
      progress: 0.0,
      sizeGB: 1.1,
      requiredRamGB: 3.0,
      fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
    ),
    AIModel(
      title: 'Gemma 2 Mobile',
      layerType: 'Google Native (2B)',
      description:
          'Built by Google. Exceptional at summarizing documents, factual Q&A, and concise writing.',
      progress: 0.0,
      sizeGB: 1.6,
      requiredRamGB: 3.5,
      fileName: 'gemma-2-2b-it-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf',
    ),
    AIModel(
      title: 'Phi-3 Mini',
      layerType: 'Smart Mobile (3.8B)',
      description:
          "Microsoft's flagship mobile brain. The perfect balance of deep reasoning, coding ability, and battery efficiency.",
      progress: 0.0,
      sizeGB: 2.4,
      requiredRamGB: 4.5,
      fileName: 'Phi-3-mini-4k-instruct-q4.gguf',
      downloadUrl:
          'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf',
    ),
    AIModel(
      title: 'Mistral v0.3',
      layerType: 'Creative Logic (7B)',
      description:
          'Highly creative and expressive. Best for long-form writing, storytelling, and complex logic puzzles.',
      progress: 0.0,
      sizeGB: 4.1,
      requiredRamGB: 7.0,
      fileName: 'Mistral-7B-Instruct-v0.3-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf',
    ),
    AIModel(
      title: 'Llama-3 Standard',
      layerType: 'Heavy Compute (8B)',
      description:
          'Desktop-class intelligence. Best for extreme coding accuracy and deep analysis. Will drain battery quickly.',
      progress: 0.0,
      sizeGB: 4.7,
      requiredRamGB: 8.0,
      fileName: 'Meta-Llama-3-8B-Instruct-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf',
    ),
  ];

  @override
  List<AIModel> build() {
    ref.onDispose(() => _updateSubscription?.cancel());
    // BUG FIX: Use post-frame callback to avoid mutating state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingModels();
      _reattachToInFlightDownloads();
    });
    return List.from(_catalog);
  }

  Future<void> _checkExistingModels() async {
    final dir = await getApplicationDocumentsDirectory();
    state = state.map((model) {
      final file = File('${dir.path}/${model.fileName}');
      return model.copyWith(
        isDownloaded: file.existsSync(),
        progress: file.existsSync() ? 1.0 : 0.0,
      );
    }).toList();
  }

  /// On app resume, check if any downloads are still in-flight and reattach
  /// the UI listener without restarting the download.
  Future<void> _reattachToInFlightDownloads() async {
    for (final model in state) {
      if (model.isDownloaded) continue;
      final record = await FileDownloader().taskForId(model.title);
      if (record != null) {
        state = state
            .map(
              (m) => m.title == model.title
                  ? m.copyWith(isDownloading: true, isPaused: false)
                  : m,
            )
            .toList();
        _attachUpdateListener();
      }
    }
  }

  /// BUG FIX: Attaches ONE shared subscription for all task updates.
  /// Called once — replaces the old pattern of creating a listener per download.
  void _attachUpdateListener() {
    if (_updateSubscription != null) return; // Already attached

    _updateSubscription = FileDownloader().updates.listen((update) {
      final taskId = update.task.taskId;

      if (update is TaskProgressUpdate) {
        double safeProgress = update.progress.clamp(0.0, 1.0);
        // Normalise if server sends 0–100 instead of 0.0–1.0
        if (safeProgress > 1.0 && safeProgress <= 100.0) {
          safeProgress = safeProgress / 100.0;
        }
        state = state
            .map(
              (m) => m.title == taskId ? m.copyWith(progress: safeProgress) : m,
            )
            .toList();
      } else if (update is TaskStatusUpdate) {
        switch (update.status) {
          case TaskStatus.complete:
            state = state
                .map(
                  (m) => m.title == taskId
                      ? m.copyWith(
                          isDownloading: false,
                          isPaused: false,
                          isDownloaded: true,
                          progress: 1.0,
                        )
                      : m,
                )
                .toList();
            break;
          case TaskStatus.paused:
            state = state
                .map(
                  (m) => m.title == taskId ? m.copyWith(isPaused: true) : m,
                )
                .toList();
            break;
          case TaskStatus.failed:
          case TaskStatus.canceled:
            state = state
                .map(
                  (m) => m.title == taskId
                      ? m.copyWith(
                          isDownloading: false,
                          isPaused: false,
                          progress: 0.0,
                        )
                      : m,
                )
                .toList();
            break;
          default:
            break;
        }
      }
    });
  }

  Future<bool> downloadModel(String targetTitle) async {
    final downloadedCount =
        state.where((m) => m.isDownloaded || m.isDownloading).length;
    if (downloadedCount >= 3) return false;

    final modelIndex = state.indexWhere((m) => m.title == targetTitle);
    if (modelIndex == -1 || state[modelIndex].downloadUrl.isEmpty) return false;

    final targetModel = state[modelIndex];
    await Permission.notification.request();

    FileDownloader().configureNotificationForGroup(
      FileDownloader.defaultGroup,
      running: TaskNotification(
        'Downloading ${targetModel.title}',
        'Neural Network installing...',
      ),
      complete: TaskNotification(
        '${targetModel.title} Ready',
        'Model installed.',
      ),
      error: TaskNotification(
        'Download Failed',
        'Could not complete installation.',
      ),
      paused: TaskNotification('Download Paused', 'Waiting to resume...'),
      progressBar: true,
    );

    final task = DownloadTask(
      taskId: targetTitle,
      url: targetModel.downloadUrl,
      filename: targetModel.fileName,
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      retries: 10,
      allowPause: true,
      requiresWiFi: false,
    );

    // BUG FIX: Attach the shared listener before enqueueing
    _attachUpdateListener();

    state = state
        .map(
          (m) => m.title == targetTitle
              ? m.copyWith(isDownloading: true, isPaused: false, progress: 0.0)
              : m,
        )
        .toList();

    await FileDownloader().enqueue(task);
    return true;
  }

  Future<void> pauseDownload(String targetTitle) async {
    final task = await FileDownloader().taskForId(targetTitle);
    if (task != null) await FileDownloader().pause(task as DownloadTask);
  }

  Future<void> resumeDownload(String targetTitle) async {
    final task = await FileDownloader().taskForId(targetTitle);
    if (task != null) {
      await FileDownloader().resume(task as DownloadTask);
      state = state
          .map(
            (m) => m.title == targetTitle ? m.copyWith(isPaused: false) : m,
          )
          .toList();
    }
  }

  Future<void> cancelDownload(String targetTitle) async {
    await FileDownloader().cancelTasksWithIds([targetTitle]);
    state = state
        .map(
          (m) => m.title == targetTitle
              ? m.copyWith(isDownloading: false, isPaused: false, progress: 0.0)
              : m,
        )
        .toList();
  }

  Future<void> deleteModel(String targetTitle) async {
    final model = state.firstWhere((m) => m.title == targetTitle);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${model.fileName}');
    if (file.existsSync()) await file.delete();

    if (ref.read(selectedModelProvider) == targetTitle) {
      ref.read(selectedModelProvider.notifier).setModel('Qwen 2.5 Fast');
    }

    state = state
        .map(
          (m) => m.title == targetTitle
              ? m.copyWith(
                  progress: 0.0,
                  isDownloading: false,
                  isPaused: false,
                  isDownloaded: false,
                )
              : m,
        )
        .toList();
  }
}

final modelsProvider = NotifierProvider<ModelsNotifier, List<AIModel>>(
  () => ModelsNotifier(),
);



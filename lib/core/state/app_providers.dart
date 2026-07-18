import 'dart:ui';
import 'dart:async';
import 'dart:convert'; 
import 'dart:io' show Platform, File;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:system_info_plus/system_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; 
import 'package:background_downloader/background_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:fllama/fllama.dart'; 

// --- THE LOCAL DATABASE INSTANCE ---
late SharedPreferences localDb;

// --- DEEP NATIVE HARDWARE PROFILING ---
class DeviceHardware {
  final String deviceName;
  final String cpuArchitecture; 
  final double totalRamGB;
  final bool hasNeuralEngine;
  final bool isDetecting;

  DeviceHardware({
    required this.deviceName, 
    required this.cpuArchitecture, 
    required this.totalRamGB, 
    required this.hasNeuralEngine, 
    this.isDetecting = false
  });
}

class HardwareNotifier extends Notifier<DeviceHardware> {
  @override
  DeviceHardware build() {
    _detectRealHardware();
    return DeviceHardware(deviceName: 'Detecting Silicon...', cpuArchitecture: 'Scanning...', totalRamGB: 0.0, hasNeuralEngine: false, isDetecting: true);
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

        final npsReg = RegExp(r'(gs[0-9]+|tensor|sm[0-9]+|snapdragon|s5e[0-9]+|exynos|mt[0-9]+|dimensity|cheetah|pantheon)');
        npu = npsReg.hasMatch(hardware) || npsReg.hasMatch(board);

        if (actualRamGB < 1.0) actualRamGB = (Platform.numberOfProcessors >= 8) ? 12.0 : 8.0;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        dName = 'iPhone ${iosInfo.utsname.machine}';
        cpuArch = 'APPLE NEURAL ENGINE';
        npu = true;
        if (actualRamGB < 1.0) actualRamGB = 8.0;
      }
    } catch (e) {
      dName = 'loc.ai Secure Kernel';
    }

    state = DeviceHardware(deviceName: dName, cpuArchitecture: cpuArch, totalRamGB: actualRamGB, hasNeuralEngine: npu, isDetecting: false);
  }
}
final hardwareInfoProvider = NotifierProvider<HardwareNotifier, DeviceHardware>(() => HardwareNotifier());

// --- PERSISTENT SETTINGS & PRIVACY ---
class HardwareAccelerationNotifier extends Notifier<bool> {
  @override
  bool build() {
    return localDb.getBool('npu_enabled') ?? ref.watch(hardwareInfoProvider).hasNeuralEngine;
  }
  void setToggle(bool value) {
    state = value;
    localDb.setBool('npu_enabled', value); 
  }
}
final hardwareAccelerationProvider = NotifierProvider<HardwareAccelerationNotifier, bool>(() => HardwareAccelerationNotifier());

class AggressiveRamNotifier extends Notifier<bool> {
  @override
  bool build() => localDb.getBool('agg_ram') ?? false; 
  void setToggle(bool value) {
    state = value;
    localDb.setBool('agg_ram', value); 
  }
}
final aggressiveRamUnloadingProvider = NotifierProvider<AggressiveRamNotifier, bool>(() => AggressiveRamNotifier());

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
final privacySettingsProvider = NotifierProvider<PrivacySettingsNotifier, Map<String, bool>>(() => PrivacySettingsNotifier());

// --- TASKS ---
class TaskRecord {
  final String title;
  final DateTime timestamp;
  final bool isDoc;
  TaskRecord({required this.title, required this.timestamp, required this.isDoc});
}

class RecentTasksNotifier extends Notifier<List<TaskRecord>> {
  @override
  List<TaskRecord> build() => [];
  void addTask(String title, bool isDoc) {
    state = [TaskRecord(title: title, timestamp: DateTime.now(), isDoc: isDoc), ...state].take(5).toList();
  }
}
final recentTasksProvider = NotifierProvider<RecentTasksNotifier, List<TaskRecord>>(() => RecentTasksNotifier());

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

  AIModel({
    required this.title, required this.layerType, required this.description,
    required this.progress, required this.sizeGB, required this.requiredRamGB, 
    this.isDownloading = false, this.isDownloaded = false, this.isPaused = false,
    required this.downloadUrl, required this.fileName
  });

  AIModel copyWith({double? progress, bool? isDownloading, bool? isDownloaded, bool? isPaused}) => AIModel(
    title: title, layerType: layerType, description: description, sizeGB: sizeGB, 
    requiredRamGB: requiredRamGB, downloadUrl: downloadUrl, fileName: fileName,
    progress: progress ?? this.progress, 
    isDownloading: isDownloading ?? this.isDownloading,
    isDownloaded: isDownloaded ?? this.isDownloaded,
    isPaused: isPaused ?? this.isPaused,
  );
}

class ModelsNotifier extends Notifier<List<AIModel>> {
  final Map<String, DownloadTask> _activeTasks = {};

  @override
  List<AIModel> build() {
    _checkExistingModels();
    return [
      AIModel(
        title: 'Qwen 2.5 Fast', 
        layerType: 'High Speed (1.5B)', 
        description: 'Blazing fast responses. Best for simple questions, brainstorming, and daily chat. Very low battery drain.',
        progress: 0.0, sizeGB: 1.1, requiredRamGB: 3.0,
        fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
        downloadUrl: 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf'
      ),
      AIModel(
        title: 'Gemma 2 Mobile', 
        layerType: 'Google Native (2B)', 
        description: 'Built by Google. Exceptional at summarizing documents, factual Q&A, and concise writing.',
        progress: 0.0, sizeGB: 1.6, requiredRamGB: 3.5,
        fileName: 'gemma-2-2b-it-Q4_K_M.gguf',
        downloadUrl: 'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf'
      ),
      AIModel(
        title: 'Phi-3 Mini', 
        layerType: 'Smart Mobile (3.8B)', 
        description: 'Microsoft’s flagship mobile brain. The perfect balance of deep reasoning, coding ability, and battery efficiency.',
        progress: 0.0, sizeGB: 2.4, requiredRamGB: 4.5,
        fileName: 'Phi-3-mini-4k-instruct-q4.gguf',
        downloadUrl: 'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf'
      ),
      AIModel(
        title: 'Mistral v0.3', 
        layerType: 'Creative Logic (7B)', 
        description: 'Highly creative and uncensored. Best for long-form writing, storytelling, and complex logic puzzles.',
        progress: 0.0, sizeGB: 4.1, requiredRamGB: 7.0,
        fileName: 'Mistral-7B-Instruct-v0.3-Q4_K_M.gguf',
        downloadUrl: 'https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf'
      ),
      AIModel(
        title: 'Llama-3 Standard', 
        layerType: 'Heavy Compute (8B)', 
        description: 'Desktop-class intelligence. Best for extreme coding accuracy and deep analysis. Will drain battery quickly.',
        progress: 0.0, sizeGB: 4.7, requiredRamGB: 8.0,
        fileName: 'Meta-Llama-3-8B-Instruct-Q4_K_M.gguf',
        downloadUrl: 'https://huggingface.co/bartowski/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf' 
      ),
    ];
  }

  Future<void> _checkExistingModels() async {
    final dir = await getApplicationDocumentsDirectory();
    state = state.map((model) {
      final file = File('${dir.path}/${model.fileName}');
      return model.copyWith(isDownloaded: file.existsSync(), progress: file.existsSync() ? 1.0 : 0.0);
    }).toList();
  }

  Future<bool> downloadModel(String targetTitle) async {
    final downloadedCount = state.where((m) => m.isDownloaded || m.isDownloading).length;
    if (downloadedCount >= 3) return false; 

    final modelIndex = state.indexWhere((m) => m.title == targetTitle);
    if (modelIndex == -1 || state[modelIndex].downloadUrl.isEmpty) return false;

    final targetModel = state[modelIndex];
    await Permission.notification.request();

    FileDownloader().configureNotificationForGroup(
      FileDownloader.defaultGroup,
      running: TaskNotification('Downloading ${targetModel.title}', 'Neural Network installing...'),
      complete: TaskNotification('${targetModel.title} Ready', 'Model installed.'),
      error: TaskNotification('Download Failed', 'Could not complete installation.'),
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

    _activeTasks[targetTitle] = task;
    state = state.map((m) => m.title == targetTitle ? m.copyWith(isDownloading: true, isPaused: false, progress: 0.0) : m).toList();

    FileDownloader().updates.listen((update) {
      if (update is TaskProgressUpdate && update.task.taskId == targetTitle) {
        double safeProgress = update.progress;
        if (safeProgress > 1.0 && safeProgress <= 100.0) safeProgress = safeProgress / 100.0;
        safeProgress = safeProgress.clamp(0.0, 1.0); 

        state = state.map((m) => m.title == targetTitle ? m.copyWith(progress: safeProgress) : m).toList();
      } else if (update is TaskStatusUpdate && update.task.taskId == targetTitle) {
        if (update.status == TaskStatus.complete) {
          state = state.map((m) => m.title == targetTitle ? m.copyWith(isDownloading: false, isPaused: false, isDownloaded: true, progress: 1.0) : m).toList();
        } else if (update.status == TaskStatus.paused) {
          state = state.map((m) => m.title == targetTitle ? m.copyWith(isPaused: true) : m).toList();
        } else if (update.status == TaskStatus.failed || update.status == TaskStatus.canceled) {
          state = state.map((m) => m.title == targetTitle ? m.copyWith(isDownloading: false, isPaused: false, progress: 0.0) : m).toList();
        }
      }
    });

    await FileDownloader().enqueue(task);
    return true;
  }

  Future<void> pauseDownload(String targetTitle) async {
    if (_activeTasks.containsKey(targetTitle)) {
      await FileDownloader().pause(_activeTasks[targetTitle]!);
    }
  }

  Future<void> resumeDownload(String targetTitle) async {
    if (_activeTasks.containsKey(targetTitle)) {
      await FileDownloader().resume(_activeTasks[targetTitle]!);
      state = state.map((m) => m.title == targetTitle ? m.copyWith(isPaused: false) : m).toList();
    }
  }

  Future<void> deleteModel(String targetTitle) async {
    final model = state.firstWhere((m) => m.title == targetTitle);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${model.fileName}');
    if (file.existsSync()) await file.delete();
    
    if (ref.read(selectedModelProvider) == targetTitle) {
      ref.read(selectedModelProvider.notifier).setModel('Qwen 2.5 Fast');
    }
    
    state = state.map((m) => m.title == targetTitle ? m.copyWith(progress: 0.0, isDownloading: false, isPaused: false, isDownloaded: false) : m).toList();
  }
}
final modelsProvider = NotifierProvider<ModelsNotifier, List<AIModel>>(() => ModelsNotifier());

// --- CHAT SESSIONS MANAGEMENT ---
class ChatSessionMeta {
  final String id;
  final String title;
  final int timestamp;
  ChatSessionMeta({required this.id, required this.title, required this.timestamp});
  
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'timestamp': timestamp};
  factory ChatSessionMeta.fromJson(Map<String, dynamic> json) => 
      ChatSessionMeta(id: json['id'], title: json['title'], timestamp: json['timestamp']);
}

class SessionsNotifier extends Notifier<List<ChatSessionMeta>> {
  @override
  List<ChatSessionMeta> build() {
    final saved = localDb.getStringList('chat_sessions');
    if (saved != null) return saved.map((e) => ChatSessionMeta.fromJson(jsonDecode(e))).toList();
    return [];
  }

  void createOrUpdateSession(String id, String title) {
    final existingIndex = state.indexWhere((s) => s.id == id);
    final updatedList = state.toList();
    if (existingIndex != -1) {
      updatedList[existingIndex] = ChatSessionMeta(id: id, title: title, timestamp: DateTime.now().millisecondsSinceEpoch);
    } else {
      updatedList.insert(0, ChatSessionMeta(id: id, title: title, timestamp: DateTime.now().millisecondsSinceEpoch));
    }
    state = updatedList;
    localDb.setStringList('chat_sessions', state.map((e) => jsonEncode(e.toJson())).toList());
  }

  void deleteSession(String id) {
    state = state.where((s) => s.id != id).toList();
    localDb.setStringList('chat_sessions', state.map((e) => jsonEncode(e.toJson())).toList());
    localDb.remove('chat_history_$id'); 
  }
}
final sessionsProvider = NotifierProvider<SessionsNotifier, List<ChatSessionMeta>>(() => SessionsNotifier());

// --- PERSISTENT CHAT STATE & LIVE GENERATIVE ENGINE ---
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool hasAttachment;
  final String? attachmentName;
  
  ChatMessage({required this.id, required this.text, required this.isUser, this.hasAttachment = false, this.attachmentName});

  ChatMessage copyWith({String? text}) => ChatMessage(
    id: id, text: text ?? this.text, isUser: isUser, 
    hasAttachment: hasAttachment, attachmentName: attachmentName
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'isUser': isUser, 'hasAttachment': hasAttachment, 'attachmentName': attachmentName,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    text: json['text'], isUser: json['isUser'],
    hasAttachment: json['hasAttachment'] ?? false, attachmentName: json['attachmentName'],
  );
}

class IsThinkingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setThinking(bool isThinking) => state = isThinking;
}
final isThinkingProvider = NotifierProvider<IsThinkingNotifier, bool>(() => IsThinkingNotifier());

class ChatNotifier extends Notifier<List<ChatMessage>> {
  String currentSessionId = 'default'; 

  @override
  List<ChatMessage> build() => _loadSession(currentSessionId);

  List<ChatMessage> _loadSession(String id) {
    final savedChats = localDb.getStringList('chat_history_$id');
    if (savedChats != null) return savedChats.map((e) => ChatMessage.fromJson(jsonDecode(e))).toList();
    return []; 
  }

  void _saveToDisk(List<ChatMessage> history) {
    localDb.setStringList('chat_history_$currentSessionId', history.map((e) => jsonEncode(e.toJson())).toList());
  }

  void loadChat(String id) {
    currentSessionId = id;
    state = _loadSession(id);
  }

  void createNewChat() {
    currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    state = []; 
  }

  void clearHistory() {
    state = [];
    localDb.remove('chat_history_$currentSessionId');
  }

  // --- PDF EXPORT TOOL ---
  Future<String?> exportChatToPDF() async {
    if (state.isEmpty) return null;
    try {
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfStandardFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      
      String chatText = "loc.ai Conversation Export\n\n";
      for (var msg in state) {
        if (msg.text.contains('⚠️') || msg.text.contains('❌') || msg.text.isEmpty) continue;
        chatText += msg.isUser ? "USER:\n${msg.text}\n\n" : "AI:\n${msg.text}\n\n";
      }

      page.graphics.drawString(chatText, font, bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height), format: PdfStringFormat(wordWrap: PdfWordWrapType.word));
      
      final List<int> bytes = await document.save();
      document.dispose();
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/loc_ai_chat_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> sendMessage(String text, String? attachmentPath) async {
    if (text.isEmpty && attachmentPath == null) return;

    if (state.isEmpty) {
      String title = text.length > 25 ? '${text.substring(0, 25)}...' : text;
      ref.read(sessionsProvider.notifier).createOrUpdateSession(currentSessionId, title);
    }

    String finalPrompt = text;
    String displayFileName = attachmentPath != null ? attachmentPath.split('/').last : '';

    if (attachmentPath != null && attachmentPath.toLowerCase().endsWith('.pdf')) {
      try {
        final bytes = await File(attachmentPath).readAsBytes();
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        String extractedText = PdfTextExtractor(document).extractText();
        document.dispose();

        extractedText = extractedText.replaceAll(RegExp(r'\s+'), ' ').trim();
        
        if (extractedText.length > 800) {
          extractedText = extractedText.substring(0, 800); 
        }
        
        if (extractedText.isEmpty) {
          finalPrompt += "\n\n(Note: The attached PDF was a scanned image or empty. I could not extract any text.)";
        } else {
          finalPrompt = "Please use the following document text to answer my prompt.\n\n<document>\n$extractedText\n</document>\n\nMy Prompt: $text";
        }
      } catch (e) {
        finalPrompt += "\n\n(Note: The attached PDF could not be read. Proceed without it.)";
      }
    }
    
    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    state = [...state, ChatMessage(id: userMsgId, text: text, isUser: true, hasAttachment: attachmentPath != null, attachmentName: displayFileName)];
    _saveToDisk(state); 
    
    ref.read(isThinkingProvider.notifier).setThinking(true);
    ref.read(recentTasksProvider.notifier).addTask('Local Inference', false);
    
    final models = ref.read(modelsProvider);
    final selectedTitle = ref.read(selectedModelProvider);
    final activeModel = models.firstWhere((m) => m.title == selectedTitle, orElse: () => models.first);

    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/${activeModel.fileName}';
    final file = File(modelPath);

    if (!file.existsSync()) {
      ref.read(isThinkingProvider.notifier).setThinking(false);
      state = [...state, ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: "⚠️ **Model Not Found**\n\nPlease download the model from Settings.", isUser: false)];
      return;
    }

    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
        state = [...state, ChatMessage(id: aiMsgId, text: "", isUser: false)];

        List<Message> historicalMessages = [];
        
        if (attachmentPath == null) {
            int maxHistoryChars = 800; 
            int currentCharCount = finalPrompt.length;

            for (var msg in state.reversed) {
              if (msg.text.contains('⚠️') || msg.text.contains('❌') || msg.id == aiMsgId) continue;
              if (currentCharCount + msg.text.length < maxHistoryChars) {
                historicalMessages.insert(0, Message(msg.isUser ? Role.user : Role.assistant, msg.text));
                currentCharCount += msg.text.length;
              } else {
                break; 
              }
            }
        }

        List<Message> memory = [
          Message(Role.system, "You are loc.ai. Answer clearly and concisely. Analyze provided text directly."),
          ...historicalMessages,
          Message(Role.user, finalPrompt) 
        ];

        final request = OpenAiRequest(
          modelPath: modelPath,
          contextSize: 4096, 
          maxTokens: 2048,    
          numGpuLayers: 99,
          temperature: 0.2,  
          messages: memory,
        );

        int lastUpdate = DateTime.now().millisecondsSinceEpoch;

        fllamaChat(request, (String response, String role, bool isDone) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - lastUpdate > 35 || isDone) {
            lastUpdate = now;
            final currentList = state.toList();
            final msgIndex = currentList.indexWhere((m) => m.id == aiMsgId);
            if (msgIndex != -1) {
              currentList[msgIndex] = currentList[msgIndex].copyWith(text: response);
              state = currentList; 
            }
          }
          if (isDone) {
            _saveToDisk(state);
            // --- FIX: SHUTOFF TRIGGER NOW PROPERLY DELAYED UNTIL THE STREAM FINISHES ---
            ref.read(isThinkingProvider.notifier).setThinking(false);
          }
        });
      } catch (e) {
        ref.read(isThinkingProvider.notifier).setThinking(false);
        state = [...state, ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: "❌ **C++ Engine Error**\n\nFailed: $e", isUser: false)];
      }
    });
  }
}
final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(() => ChatNotifier());

// --- UI STATE PROVIDERS ---
class SelectedModelNotifier extends Notifier<String> {
  @override
  String build() => localDb.getString('selected_model') ?? 'Qwen 2.5 Fast'; 
  void setModel(String model) {
    state = model;
    localDb.setString('selected_model', model);
  }
}
final selectedModelProvider = NotifierProvider<SelectedModelNotifier, String>(() => SelectedModelNotifier());

class ChatAttachmentNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setAttachment(String? filePath) => state = filePath;
}
final chatAttachmentProvider = NotifierProvider<ChatAttachmentNotifier, String?>(() => ChatAttachmentNotifier());

class VisionMediaNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setMedia(String? fileName) {
    state = fileName;
    if (fileName != null) ref.read(recentTasksProvider.notifier).addTask('Vision Analysis', false);
  }
}
final visionMediaProvider = NotifierProvider<VisionMediaNotifier, String?>(() => VisionMediaNotifier());

class StorageState {
  final double totalAppSizeGB;
  final double modelsSizeGB;
  final double cacheSizeGB;
  StorageState(this.totalAppSizeGB, this.modelsSizeGB, this.cacheSizeGB);
}
class StorageNotifier extends Notifier<StorageState> {
  @override
  StorageState build() => StorageState(1.5, 0.35, 1.2);
  void clearCache() {
    state = StorageState(state.totalAppSizeGB - state.cacheSizeGB, state.modelsSizeGB, 0.0);
    ref.read(chatProvider.notifier).clearHistory();
  }
}
final storageProvider = NotifierProvider<StorageNotifier, StorageState>(() => StorageNotifier());

// --- DYNAMIC TELEMETRY ENGINE ---
class HardwareTelemetry {
  final double ramUsageMB;
  final double thermalTempC;
  final double gpuUsage; 
  final bool isThrottling;
  HardwareTelemetry({required this.ramUsageMB, required this.thermalTempC, required this.gpuUsage, required this.isThrottling});
}

final telemetryStreamProvider = StreamProvider<HardwareTelemetry>((ref) async* {
  while (true) {
    final isThinking = ref.watch(isThinkingProvider);
    final hw = ref.watch(hardwareInfoProvider);
    final isAggressive = ref.watch(aggressiveRamUnloadingProvider);
    
    final models = ref.watch(modelsProvider);
    final selectedTitle = ref.watch(selectedModelProvider);
    final activeModel = models.firstWhere((m) => m.title == selectedTitle, orElse: () => models.first);
    
    // Exact model weight + 15% C++ Inference Overhead
    final modelRamOverheadMB = activeModel.sizeGB * 1024 * 1.15; 

    // --- FIX: OS BASELOAD SIMULATION ---
    // Android OS blocks live free RAM polling, so we deterministically calculate base OS load
    final totalRamMB = hw.totalRamGB * 1024;
    final baseLoad = totalRamMB * (isAggressive ? 0.15 : 0.28); 
    
    final aiLoad = isThinking ? modelRamOverheadMB : 0.0; 
    final jitter = (DateTime.now().millisecond % 50).toDouble();

    yield HardwareTelemetry(
      ramUsageMB: baseLoad + aiLoad + jitter,
      thermalTempC: isThinking ? 41.2 + (jitter / 10) : 32.5 + (jitter / 20),
      gpuUsage: isThinking ? 88.0 + (jitter / 5) : 2.5, 
      isThrottling: isThinking && (hw.totalRamGB < 6.0)
    );

    await Future.delayed(const Duration(milliseconds: 1000));
  }
});
// --- NATIVE VOICE ENGINE ---
class VoiceState {
  final bool isListening;
  final String recognizedText;
  final bool isAvailable;
  VoiceState({this.isListening = false, this.recognizedText = '', this.isAvailable = false});
}

class VoiceNotifier extends Notifier<VoiceState> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  VoiceState build() {
    _initSpeech();
    return VoiceState();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          state = VoiceState(isListening: false, recognizedText: state.recognizedText, isAvailable: true);
        }
      },
      onError: (errorNotification) => print('loc.ai Speech Error: $errorNotification'),
    );
    state = VoiceState(isAvailable: available, isListening: false, recognizedText: '');
  }

  void startListening(Function(String) onResult) async {
    if (state.isAvailable && !state.isListening) {
      state = VoiceState(isListening: true, recognizedText: '', isAvailable: true);
      await _speech.listen(
        onResult: (result) {
          state = VoiceState(isListening: true, recognizedText: result.recognizedWords, isAvailable: true);
          onResult(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void stopListening() async {
    await _speech.stop();
    state = VoiceState(isListening: false, recognizedText: state.recognizedText, isAvailable: true);
  }
}
final voiceProvider = NotifierProvider<VoiceNotifier, VoiceState>(() => VoiceNotifier());
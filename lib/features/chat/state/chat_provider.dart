import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:fllama/fllama.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart'; // for compute
import '../../../core/db/database_helper.dart';
import 'chat_sessions_provider.dart';
import 'ui_state_provider.dart';
import '../../../features/models/state/models_provider.dart';
import '../../../core/state/tasks_provider.dart';
import '../../../core/state/ai_state_provider.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool hasAttachment;
  final String? attachmentName;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.hasAttachment = false,
    this.attachmentName,
  });

  ChatMessage copyWith({String? text}) => ChatMessage(
    id: id,
    text: text ?? this.text,
    isUser: isUser,
    hasAttachment: hasAttachment,
    attachmentName: attachmentName,
  );

  Map<String, dynamic> toJson(String sessionId) => {
    'id': id,
    'session_id': sessionId,
    'text': text,
    'isUser': isUser ? 1 : 0,
    'hasAttachment': hasAttachment ? 1 : 0,
    'attachmentName': attachmentName,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    text: json['text'],
    isUser: json['isUser'] == 1,
    hasAttachment: json['hasAttachment'] == 1,
    attachmentName: json['attachmentName'],
  );
}

class IsThinkingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setThinking(bool isThinking) => state = isThinking;
}

final isThinkingProvider =
    NotifierProvider<IsThinkingNotifier, bool>(() => IsThinkingNotifier());

class ChatNotifier extends Notifier<List<ChatMessage>> {
  String currentSessionId = 'default';

  @override
  List<ChatMessage> build() {
    _loadSessionFromDb(currentSessionId);
    return [];
  }

  Future<void> _loadSessionFromDb(String id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [id],
      orderBy: 'timestamp ASC',
    );
    state = result.map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<void> _saveMessageToDb(ChatMessage msg) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'messages',
      msg.toJson(currentSessionId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<void> _updateMessageTextInDb(String msgId, String newText) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'messages',
      {'text': newText},
      where: 'id = ?',
      whereArgs: [msgId],
    );
  }

  void loadChat(String id) {
    currentSessionId = id;
    _loadSessionFromDb(id);
  }

  void createNewChat() {
    currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    state = [];
  }

  void clearHistory() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('messages', where: 'session_id = ?', whereArgs: [currentSessionId]);
    state = [];
  }

  // Heavy PDF Extraction offloaded to Isolate (Phase 3)
  static Future<String> _extractPdfText(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String extractedText = PdfTextExtractor(document).extractText();
      document.dispose();
      extractedText = extractedText.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (extractedText.length > 800) {
        extractedText = extractedText.substring(0, 800);
      }
      return extractedText;
    } catch (_) {
      return '';
    }
  }

  Future<String?> exportChatToPDF() async {
    if (state.isEmpty) return null;
    try {
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfStandardFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);

      String chatText = 'EdgeX Conversation Export\n\n';
      for (final msg in state) {
        if (msg.text.contains('⚠️') ||
            msg.text.contains('❌') ||
            msg.text.isEmpty) {
          continue;
        }
        chatText +=
            msg.isUser ? 'USER:\n${msg.text}\n\n' : 'AI:\n${msg.text}\n\n';
      }

      page.graphics.drawString(
        chatText,
        font,
        bounds: Rect.fromLTWH(
          0,
          0,
          page.getClientSize().width,
          page.getClientSize().height,
        ),
        format: PdfStringFormat(wordWrap: PdfWordWrapType.word),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/edgex_chat_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> sendMessage(String text, String? attachmentPath) async {
    if (text.isEmpty && attachmentPath == null) return;

    if (state.isEmpty) {
      final title = text.length > 25 ? '\${text.substring(0, 25)}...' : text;
      ref
          .read(sessionsProvider.notifier)
          .createOrUpdateSession(currentSessionId, title);
    }

    String finalPrompt = text;
    final String displayFileName =
        attachmentPath != null ? attachmentPath.split('/').last : '';

    if (attachmentPath != null &&
        attachmentPath.toLowerCase().endsWith('.pdf')) {
      // PHASE 3: Offload heavy extraction to Isolate to prevent UI freeze
      final extractedText = await compute(_extractPdfText, attachmentPath);
      if (extractedText.isEmpty) {
        finalPrompt += '\n\n(Note: The attached PDF could not be read or was empty.)';
      } else {
        finalPrompt = 'Please use the following document text to answer my prompt.\n\n<document>\n\$extractedText\n</document>\n\nMy Prompt: $text';
      }
    }

    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    final userMsg = ChatMessage(
        id: userMsgId,
        text: text,
        isUser: true,
        hasAttachment: attachmentPath != null,
        attachmentName: displayFileName,
      );
    
    state = [...state, userMsg];
    await _saveMessageToDb(userMsg);

    ref.read(isThinkingProvider.notifier).setThinking(true);
    ref.read(recentTasksProvider.notifier).addTask('Local Inference', false);

    final models = ref.read(modelsProvider);
    final selectedTitle = ref.read(selectedModelProvider);
    final activeModel = models.firstWhere(
      (m) => m.title == selectedTitle,
      orElse: () => models.first,
    );

    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/${activeModel.fileName}';
    final file = File(modelPath);

    if (!file.existsSync()) {
      ref.read(isThinkingProvider.notifier).setThinking(false);
      state = [
        ...state,
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '⚠️ **Model Not Found**\n\nPlease download a model from the Settings tab.',
          isUser: false,
        ),
      ];
      return;
    }

    await Future.delayed(const Duration(milliseconds: 16));

    try {
      final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
      final initialAiMsg = ChatMessage(id: aiMsgId, text: '', isUser: false);
      state = [...state, initialAiMsg];
      await _saveMessageToDb(initialAiMsg);

      List<Message> historicalMessages = [];

      if (attachmentPath == null) {
        const int maxHistoryChars = 3200;
        int currentCharCount = finalPrompt.length;

        for (final msg in state.reversed) {
          if (msg.text.contains('⚠️') ||
              msg.text.contains('❌') ||
              msg.id == aiMsgId) { continue; }
          if (currentCharCount + msg.text.length < maxHistoryChars) {
            historicalMessages.insert(
              0,
              Message(msg.isUser ? Role.user : Role.assistant, msg.text),
            );
            currentCharCount += msg.text.length;
          } else {
            break;
          }
        }
      }

      final List<Message> memory = [
        Message(
          Role.system,
          'You are EdgeX, a powerful private on-device AI assistant. '
          'You run 100% locally with no internet connection. '
          'Answer clearly, accurately, and concisely. Format responses with Markdown where appropriate.',
        ),
        ...historicalMessages,
        Message(Role.user, finalPrompt),
      ];

      final request = OpenAiRequest(
        modelPath: modelPath,
        contextSize: 4096,
        maxTokens: 2048,
        numGpuLayers: 99,
        temperature: 0.2,
        messages: memory,
      );

      int lastUpdateMs = DateTime.now().millisecondsSinceEpoch;
      int tokenCount = 0;
      final inferenceStartMs = DateTime.now().millisecondsSinceEpoch;

      fllamaChat(request, (String response, String role, bool isDone) {
        final now = DateTime.now().millisecondsSinceEpoch;
        tokenCount++;

        // Optimally rebuild UI without freezing main thread
        if (now - lastUpdateMs > 40 || isDone) {
          lastUpdateMs = now;
          final currentList = state.toList();
          final msgIndex = currentList.indexWhere((m) => m.id == aiMsgId);
          if (msgIndex != -1) {
            currentList[msgIndex] = currentList[msgIndex].copyWith(
              text: response,
            );
            state = currentList;
          }

          // Wire real token/s speed into aiStateProvider
          final elapsedSec = (now - inferenceStartMs) / 1000.0;
          if (elapsedSec > 0) {
            final tokensPerSec = (tokenCount / elapsedSec).round().clamp(1, 999);
            ref.read(aiStateProvider.notifier).updateTelemetry(speedTs: tokensPerSec);
          }
        }

        if (isDone) {
          _updateMessageTextInDb(aiMsgId, response);
          ref.read(isThinkingProvider.notifier).setThinking(false);
          ref.read(aiStateProvider.notifier).updateTelemetry(speedTs: 0);
        }
      });
    } catch (e) {
      ref.read(isThinkingProvider.notifier).setThinking(false);
      state = [
        ...state,
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '❌ **Engine Error**\n\nFailed to load model: $e',
          isUser: false,
        ),
      ];
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(
  () => ChatNotifier(),
);

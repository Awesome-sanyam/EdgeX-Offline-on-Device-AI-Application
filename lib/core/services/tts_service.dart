import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsState {
  final bool isSpeaking;
  final String? speakingMessageId;

  const TtsState({this.isSpeaking = false, this.speakingMessageId});
}

class TtsNotifier extends Notifier<TtsState> {
  final FlutterTts _tts = FlutterTts();

  @override
  TtsState build() {
    _init();
    ref.onDispose(() => _tts.stop());
    return const TtsState();
  }

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.52);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      state = const TtsState(isSpeaking: false, speakingMessageId: null);
    });

    _tts.setErrorHandler((_) {
      state = const TtsState(isSpeaking: false, speakingMessageId: null);
    });
  }

  Future<void> speak(String text, String messageId) async {
    // Strip markdown formatting for cleaner TTS
    final cleaned = text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'`{1,3}[^`]*`{1,3}'), 'code block')
        .replaceAll(RegExp(r'#{1,6} '), '')
        .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1')
        .replaceAll(RegExp(r'[*_~]'), '')
        .trim();

    if (state.isSpeaking && state.speakingMessageId == messageId) {
      await stop();
      return;
    }

    if (state.isSpeaking) {
      await _tts.stop();
    }

    HapticFeedback.lightImpact();
    state = TtsState(isSpeaking: true, speakingMessageId: messageId);
    await _tts.speak(cleaned);
  }

  Future<void> stop() async {
    HapticFeedback.lightImpact();
    await _tts.stop();
    state = const TtsState(isSpeaking: false, speakingMessageId: null);
  }
}

final ttsProvider = NotifierProvider<TtsNotifier, TtsState>(() => TtsNotifier());

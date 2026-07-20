import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// --- NATIVE VOICE ENGINE ---

class VoiceState {
  final bool isListening;
  final String recognizedText;
  final bool isAvailable;

  const VoiceState({
    this.isListening = false,
    this.recognizedText = '',
    this.isAvailable = false,
  });
}

class VoiceNotifier extends Notifier<VoiceState> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  VoiceState build() {
    _initSpeech();
    return const VoiceState();
  }

  Future<void> _initSpeech() async {
    final bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          state = VoiceState(
            isListening: false,
            recognizedText: state.recognizedText,
            isAvailable: true,
          );
        }
      },
      onError: (_) {
        // Silently handle — voice is non-critical
      },
    );
    state = VoiceState(isAvailable: available, isListening: false);
  }

  void startListening(Function(String) onResult) async {
    if (state.isAvailable && !state.isListening) {
      state = VoiceState(
        isListening: true,
        recognizedText: '',
        isAvailable: true,
      );
      await _speech.listen(
        onResult: (result) {
          state = VoiceState(
            isListening: true,
            recognizedText: result.recognizedWords,
            isAvailable: true,
          );
          onResult(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    }
  }

  void stopListening() async {
    await _speech.stop();
    state = VoiceState(
      isListening: false,
      recognizedText: state.recognizedText,
      isAvailable: true,
    );
  }
}

final voiceProvider =
    NotifierProvider<VoiceNotifier, VoiceState>(() => VoiceNotifier());

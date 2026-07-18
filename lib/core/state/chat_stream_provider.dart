import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveStreamNotifier extends Notifier<String> {
  @override
  String build() => "";

  void appendToken(String token) {
    state = state + token;
  }

  void clear() => state = "";
}

final activeStreamProvider = NotifierProvider<ActiveStreamNotifier, String>(() {
  return ActiveStreamNotifier();
});

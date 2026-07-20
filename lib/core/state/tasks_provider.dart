import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    state = [
      TaskRecord(title: title, timestamp: DateTime.now(), isDoc: isDoc),
      ...state,
    ].take(5).toList();
  }
}

final recentTasksProvider =
    NotifierProvider<RecentTasksNotifier, List<TaskRecord>>(
      () => RecentTasksNotifier(),
    );



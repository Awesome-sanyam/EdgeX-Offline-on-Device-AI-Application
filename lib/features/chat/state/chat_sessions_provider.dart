import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/database_helper.dart';

class ChatSessionMeta {
  final String id;
  final String title;
  final int timestamp;

  ChatSessionMeta({
    required this.id,
    required this.title,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'timestamp': timestamp};

  factory ChatSessionMeta.fromJson(Map<String, dynamic> json) =>
      ChatSessionMeta(
        id: json['id'],
        title: json['title'],
        timestamp: json['timestamp'],
      );
}

class SessionsNotifier extends Notifier<List<ChatSessionMeta>> {
  @override
  List<ChatSessionMeta> build() {
    _loadSessions();
    return [];
  }

  Future<void> _loadSessions() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('sessions', orderBy: 'timestamp DESC');
    state = result.map((e) => ChatSessionMeta.fromJson(e)).toList();
  }

  Future<void> createOrUpdateSession(String id, String title) async {
    final db = await DatabaseHelper.instance.database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert('sessions', {
      'id': id,
      'title': title,
      'timestamp': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace); // Upsert

    await _loadSessions();
  }

  Future<void> deleteSession(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
    // Cascade delete in DatabaseHelper removes associated messages automatically
    await _loadSessions();
  }
}

final sessionsProvider =
    NotifierProvider<SessionsNotifier, List<ChatSessionMeta>>(
      () => SessionsNotifier(),
    );

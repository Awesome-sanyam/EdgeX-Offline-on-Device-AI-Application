import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edgex_chat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE sessions (
  id $idType,
  title $textType,
  timestamp $integerType
)
''');

    await db.execute('''
CREATE TABLE messages (
  id $idType,
  session_id TEXT NOT NULL,
  text $textType,
  isUser $boolType,
  hasAttachment $boolType,
  attachmentName TEXT,
  timestamp $integerType,
  FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE INDEX idx_session_id ON messages (session_id)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

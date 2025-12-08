import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('staytics.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE sessions ( 
  id $idType, 
  day $textType,
  date $textType,
  seconds $intType,
  progress $realType,
  break_time $intType DEFAULT 0,
  break_count $intType DEFAULT 0
  )
''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Use try-catch to handle cases where columns might already exist
      try {
        await db.execute(
          'ALTER TABLE sessions ADD COLUMN break_time INTEGER DEFAULT 0',
        );
      } catch (e) {
        // Column likely exists, ignore
      }
      try {
        await db.execute(
          'ALTER TABLE sessions ADD COLUMN break_count INTEGER DEFAULT 0',
        );
      } catch (e) {
        // Column likely exists, ignore
      }
    }
  }

  Future<void> insertSession(Map<String, dynamic> session) async {
    final db = await instance.database;
    await db.insert(
      'sessions',
      session,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await instance.database;
    return await db.query('sessions');
  }

  Future<List<Map<String, dynamic>>> getSessionsForWeek(
    DateTime startOfWeek,
  ) async {
    final db = await instance.database;
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final startStr = startOfWeek.toIso8601String().substring(0, 10);
    final endStr = endOfWeek.toIso8601String().substring(0, 10);

    return await db.query(
      'sessions',
      where: 'date >= ? AND date < ?',
      whereArgs: [startStr, endStr],
    );
  }

  Future<List<Map<String, dynamic>>> getSessionsForMonth(DateTime month) async {
    final db = await instance.database;

    // Start of the month
    final startOfMonth = DateTime(month.year, month.month, 1);
    // Start of the next month (which is the exclusive end of the current month)
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    final startStr = startOfMonth.toIso8601String().substring(0, 10);
    final endStr = endOfMonth.toIso8601String().substring(0, 10);

    return await db.query(
      'sessions',
      where: 'date >= ? AND date < ?',
      whereArgs: [startStr, endStr],
    );
  }

  Future<void> deleteAllSessions() async {
    final db = await instance.database;
    await db.delete('sessions');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'staytics.db');
  }
}

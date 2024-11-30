import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/squat_record.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'squat_records.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE squat_records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dateTime TEXT NOT NULL,
            count INTEGER NOT NULL,
            accuracy REAL NOT NULL,
            duration INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db
              .execute('ALTER TABLE squat_records RENAME TO squat_records_old');

          await db.execute('''
            CREATE TABLE squat_records(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              dateTime TEXT NOT NULL,
              count INTEGER NOT NULL,
              accuracy REAL NOT NULL,
              duration INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            INSERT INTO squat_records (id, dateTime, count, accuracy, duration)
            SELECT id, dateTime, count, 0.0, duration
            FROM squat_records_old
          ''');

          await db.execute('DROP TABLE squat_records_old');
        }
      },
    );
  }

  Future<int> insertRecord(SquatRecord record) async {
    final db = await database;
    return db.insert('squat_records', record.toMap());
  }

  Future<List<SquatRecord>> getRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'squat_records',
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) => SquatRecord.fromMap(maps[i]));
  }

  Future<List<SquatRecord>> getRecordsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'squat_records',
      where: 'dateTime BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) => SquatRecord.fromMap(maps[i]));
  }

  Future<List<SquatRecord>> getRecordsByMonth(int year, int month) async {
    final db = await database;
    final startOfMonth = DateTime(year, month);
    final endOfMonth = DateTime(year, month + 1);

    final List<Map<String, dynamic>> maps = await db.query(
      'squat_records',
      where: 'dateTime BETWEEN ? AND ?',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) => SquatRecord.fromMap(maps[i]));
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete(
      'squat_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

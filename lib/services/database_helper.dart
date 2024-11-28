import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout_session.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workout_tracker.db');
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workout_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        squatCount INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        averageDuration REAL NOT NULL,
        caloriesBurned REAL NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_workout_sessions_startTime ON workout_sessions(startTime)');

    await db.execute('''
      CREATE TABLE exercise_sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER NOT NULL,
        repetitions INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        duration INTEGER NOT NULL,
        FOREIGN KEY (sessionId) REFERENCES workout_sessions (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertWorkoutSession(WorkoutSession session) async {
    try {
      final db = await database;
      final id = await db.insert('workout_sessions', session.toMap());

      for (var set in session.sets) {
        await db.insert('exercise_sets', {
          'sessionId': id,
          'repetitions': set.repetitions,
          'accuracy': set.accuracy,
          'duration': set.duration.inMilliseconds,
        });
      }

      return id;
    } catch (e) {
      throw Exception('운동 세션 저장 중 오류가 발생했습니다. Error: $e');
    }
  }

  Future<List<WorkoutSession>> getWorkoutSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('workout_sessions');

    return List.generate(maps.length, (i) {
      return WorkoutSession.fromMap(maps[i]);
    });
  }

  Future<List<ExerciseSet>> getExerciseSets(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercise_sets',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );

    return List.generate(maps.length, (i) {
      return ExerciseSet(
        repetitions: maps[i]['repetitions'],
        accuracy: maps[i]['accuracy'],
        duration: Duration(milliseconds: maps[i]['duration']),
      );
    });
  }

  Future<List<WorkoutSession>> getAllWorkoutSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('workout_sessions', orderBy: 'startTime DESC');

    return List.generate(maps.length, (i) {
      return WorkoutSession.fromMap(maps[i]);
    });
  }

  Future<void> deleteAllWorkoutSessions() async {
    final db = await database;
    await db.delete('workout_sessions');
  }

  Future<void> insertWorkoutSessionBatch(List<WorkoutSession> sessions) async {
    final db = await database;
    final batch = db.batch();

    for (var session in sessions) {
      batch.insert('workout_sessions', session.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<List<WorkoutSession>> getWorkoutSessionsPaginated({
    required int limit,
    required int offset,
  }) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'workout_sessions',
        orderBy: 'startTime DESC',
        limit: limit,
        offset: offset,
      );

      return List.generate(maps.length, (i) => WorkoutSession.fromMap(maps[i]));
    } catch (e) {
      throw Exception('운동 기록을 불러오는 중 오류가 발생했습니다. Error: $e');
    }
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout_session.dart';
import '../models/achievement_badge.dart';

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
        caloriesBurned REAL NOT NULL,
        feedbacks TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER NOT NULL,
        repetitions INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        duration INTEGER NOT NULL,
        feedbacks TEXT,
        FOREIGN KEY (sessionId) REFERENCES workout_sessions (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        iconPath TEXT NOT NULL,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        unlockedAt TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_workout_sessions_startTime ON workout_sessions(startTime)',
    );
  }

  Future<int> insertWorkoutSession(WorkoutSession session) async {
    final db = await database;
    final id = await db.insert('workout_sessions', session.toMap());

    for (var set in session.sets) {
      await db.insert('exercise_sets', {
        'sessionId': id,
        'repetitions': set.repetitions,
        'accuracy': set.accuracy,
        'duration': set.duration.inMilliseconds,
        'feedbacks': set.feedbacks.join('|'),
      });
    }

    return id;
  }

  Future<List<WorkoutSession>> getWorkoutSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workout_sessions',
      orderBy: 'startTime DESC',
    );

    return Future.wait(maps.map((map) async {
      final session = WorkoutSession.fromMap(map);
      final sets = await getExerciseSets(session.id!);
      return session.copyWith(sets: sets);
    }).toList());
  }

  Future<List<ExerciseSet>> getExerciseSets(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercise_sets',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );

    return maps
        .map((map) => ExerciseSet(
              repetitions: map['repetitions'],
              accuracy: map['accuracy'],
              duration: Duration(milliseconds: map['duration']),
              feedbacks: (map['feedbacks'] as String?)?.split('|') ?? [],
            ))
        .toList();
  }

  Future<void> insertAchievement(AchievementBadge badge) async {
    final db = await database;
    await db.insert('achievements', {
      'id': badge.id,
      'title': badge.title,
      'description': badge.description,
      'iconPath': badge.iconPath,
      'isUnlocked': badge.isUnlocked ? 1 : 0,
      'unlockedAt': badge.unlockedAt?.toIso8601String(),
    });
  }

  Future<List<AchievementBadge>> getAchievements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('achievements');

    return maps
        .map((map) => AchievementBadge(
              id: map['id'],
              title: map['title'],
              description: map['description'],
              iconPath: map['iconPath'],
              isUnlocked: map['isUnlocked'] == 1,
              unlockedAt: map['unlockedAt'] != null
                  ? DateTime.parse(map['unlockedAt'])
                  : null,
            ))
        .toList();
  }

  Future<void> unlockAchievement(String achievementId) async {
    final db = await database;
    await db.update(
      'achievements',
      {
        'isUnlocked': 1,
        'unlockedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [achievementId],
    );
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('workout_sessions');
    await db.delete('exercise_sets');
    await db.delete('achievements');
  }
}

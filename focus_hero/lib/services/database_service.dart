import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import '../models/profile.dart';
import '../models/tomato_session.dart';
import '../models/achievement.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'focus_hero.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY DEFAULT 1,
        username TEXT,
        level INTEGER DEFAULT 1,
        exp INTEGER DEFAULT 0,
        total_tomatoes INTEGER DEFAULT 0,
        max_streak INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.insert('profiles', {
      'id': 1,
      'username': '专注英雄',
      'level': 1,
      'exp': 0,
      'total_tomatoes': 0,
      'max_streak': 0,
      'updated_at': DateTime.now().toIso8601String()
    });

    await db.execute('''
      CREATE TABLE tomato_sessions (
        id TEXT PRIMARY KEY,
        completed_at TEXT,
        duration INTEGER,
        interrupted INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        achievement_key TEXT,
        unlocked_at TEXT
      )
    ''');
  }

  // Handle zombie sessions (not finished properly)
  Future<void> handleZombieSessions() async {
    // In this local version, we can check a shared_preference flag
    // to see if a session was active when the app closed.
    // This will be handled in the Timer Provider/Service.
  }

  // Profile Methods
  Future<Profile> getProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('profiles', where: 'id = ?', whereArgs: [1]);
    return Profile.fromMap(maps.first);
  }

  Future<void> updateProfile(Profile profile) async {
    final db = await database;
    await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Session Methods
  Future<void> insertSession(TomatoSession session) async {
    final db = await database;
    await db.insert('tomato_sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TomatoSession>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tomato_sessions', orderBy: 'completed_at DESC');
    return List.generate(maps.length, (i) => TomatoSession.fromMap(maps[i]));
  }

  // Achievement Methods
  Future<void> insertAchievement(Achievement achievement) async {
    final db = await database;
    await db.insert('achievements', achievement.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Achievement>> getAchievements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('achievements');
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }
}

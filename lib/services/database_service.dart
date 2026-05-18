import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/nutrition_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cek_piringku.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN school TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT,
        grade TEXT,
        school TEXT,
        email TEXT UNIQUE,
        password TEXT,
        points INTEGER,
        streak INTEGER,
        totalScans INTEGER
      )
    ''');

    // Scans Table (Existing)
    await db.execute('''
      CREATE TABLE scans(
        id TEXT PRIMARY KEY,
        timestamp TEXT,
        calories INTEGER,
        protein INTEGER,
        carbs INTEGER,
        fats INTEGER,
        foodItems TEXT,
        isStandardMet INTEGER
      )
    ''');
  }

  // --- Auth Operations ---
  Future<void> registerUser(String name, String grade, String school, String email, String password) async {
    final db = await database;
    await db.insert('users', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'grade': grade,
      'school': school,
      'email': email,
      'password': password,
      'points': 0,
      'streak': 0,
      'totalScans': 0
    });
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isEmpty) return null;
    return maps[0];
  }

  // --- User Operations ---
  Future<User?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isEmpty) return null;
    
    return User(
      name: maps[0]['name'],
      grade: maps[0]['grade'],
      school: maps[0]['school'] ?? 'Sekolah Dasar',
      points: maps[0]['points'],
      streak: maps[0]['streak'],
      totalScans: maps[0]['totalScans'],
    );
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      {
        'points': user.points,
        'streak': user.streak,
        'totalScans': user.totalScans,
      },
      where: 'id = ?',
      whereArgs: ['u1'],
    );
  }

  // --- Scan Operations ---
  Future<void> insertScan(NutritionModel scan) async {
    final db = await database;
    await db.insert(
      'scans',
      {
        'id': scan.id,
        'timestamp': scan.timestamp.toIso8601String(),
        'calories': scan.calories,
        'protein': scan.protein,
        'carbs': scan.carbs,
        'fats': scan.fats,
        'foodItems': jsonEncode(scan.foodItems),
        'isStandardMet': scan.isStandardMet ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NutritionModel>> getScans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('scans', orderBy: 'timestamp DESC');

    return List.generate(maps.length, (i) {
      return NutritionModel(
        id: maps[i]['id'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
        calories: maps[i]['calories'],
        protein: maps[i]['protein'],
        carbs: maps[i]['carbs'],
        fats: maps[i]['fats'],
        foodItems: List<String>.from(jsonDecode(maps[i]['foodItems'])),
        isStandardMet: maps[i]['isStandardMet'] == 1,
      );
    });
  }
}

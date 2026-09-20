import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return instance;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'socialshieldai.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE scan_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            profile_username TEXT NOT NULL,
            prediction TEXT NOT NULL,
            confidence REAL NOT NULL,
            confidence_level TEXT NOT NULL,
            risk_factors TEXT,
            scanned_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ==========================================================
  // REGISTER USER
  // ==========================================================

  Future<bool> registerUser(
    String name,
    String username,
    String email,
    String password,
  ) async {
    final db = await database;

    try {
      await db.insert(
        'users',
        {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================
  // LOGIN USER
  // ==========================================================

  Future<Map<String, dynamic>?> loginUser(
    String usernameOrEmail,
    String password,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND password = ?',
      whereArgs: [
        usernameOrEmail,
        usernameOrEmail,
        password,
      ],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  // ==========================================================
  // CHECK USERNAME / EMAIL
  // ==========================================================

  Future<bool> userExists(String usernameOrEmail) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'username = ? OR email = ?',
      whereArgs: [
        usernameOrEmail,
        usernameOrEmail,
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ==========================================================
  // RESET PASSWORD
  // ==========================================================

  Future<bool> resetPassword(
    String usernameOrEmail,
    String newPassword,
  ) async {
    final db = await database;

    final count = await db.update(
      'users',
      {
        'password': newPassword,
      },
      where: 'username = ? OR email = ?',
      whereArgs: [
        usernameOrEmail,
        usernameOrEmail,
      ],
    );

    return count > 0;
  }

  // ==========================================================
  // SAVE SCAN HISTORY
  // ==========================================================

  Future<void> saveScanHistory({
    int? userId,
    required String profileUsername,
    required String prediction,
    required double confidence,
    required String confidenceLevel,
    required String riskFactors,
  }) async {
    final db = await database;

    await db.insert(
      'scan_history',
      {
        'user_id': userId,
        'profile_username': profileUsername,
        'prediction': prediction,
        'confidence': confidence,
        'confidence_level': confidenceLevel,
        'risk_factors': riskFactors,
        'scanned_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==========================================================
  // GET SCAN HISTORY
  // ==========================================================

  Future<List<Map<String, dynamic>>> getScanHistory(
    int userId,
  ) async {
    final db = await database;

    return await db.query(
      'scan_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'scanned_at DESC',
    );
  }
}
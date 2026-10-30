import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'nexus_router.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createMeta(db);
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createMeta(db);
        }
      },
    );
  }

  Future<void> _createMeta(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
          CREATE TABLE devices (
            mac TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            vendor TEXT NOT NULL,
            type TEXT NOT NULL,
            ip TEXT NOT NULL,
            online INTEGER NOT NULL DEFAULT 0,
            favorite INTEGER NOT NULL DEFAULT 0,
            trusted INTEGER NOT NULL DEFAULT 0,
            blocked INTEGER NOT NULL DEFAULT 0,
            grp TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            first_seen INTEGER NOT NULL,
            last_seen INTEGER NOT NULL
          )
        ''');

    await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mac TEXT,
            kind TEXT NOT NULL,
            severity TEXT NOT NULL,
            title TEXT NOT NULL,
            detail TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

    await db.execute(
      'CREATE INDEX idx_events_created ON events (created_at DESC)',
    );
    await db.execute('CREATE INDEX idx_events_mac ON events (mac)');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

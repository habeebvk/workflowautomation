import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/timetable_model.dart';

class TimetableDatabaseService {
  static final TimetableDatabaseService _instance =
      TimetableDatabaseService._internal();
  factory TimetableDatabaseService() => _instance;
  TimetableDatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'timetable.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE timetable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        period INTEGER NOT NULL,
        teacherName TEXT NOT NULL,
        subject TEXT NOT NULL,
        className TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        attendance TEXT NOT NULL
      )
    ''');
  }

  /// Insert a timetable entry
  Future<int> insertEntry(TimetableEntry entry) async {
    final db = await database;
    return await db.insert('timetable', entry.toMap());
  }

  /// Insert multiple entries (for bulk upload)
  Future<void> insertMultipleEntries(List<TimetableEntry> entries) async {
    final db = await database;
    Batch batch = db.batch();
    for (var entry in entries) {
      batch.insert('timetable', entry.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Get all entries for a specific day
  Future<List<TimetableEntry>> getEntriesByDay(String day) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'timetable',
      where: 'day = ?',
      whereArgs: [day],
      orderBy: 'period ASC',
    );
    return List.generate(maps.length, (i) => TimetableEntry.fromMap(maps[i]));
  }

  /// Get all entries
  Future<List<TimetableEntry>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('timetable');
    return List.generate(maps.length, (i) => TimetableEntry.fromMap(maps[i]));
  }

  /// Update attendance status
  Future<int> updateAttendance(int id, String attendance) async {
    final db = await database;
    return await db.update(
      'timetable',
      {'attendance': attendance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Swap two teachers' assignments
  Future<void> swapTeachers(int entry1Id, int entry2Id) async {
    final db = await database;

    // Get both entries
    final entry1Maps = await db.query(
      'timetable',
      where: 'id = ?',
      whereArgs: [entry1Id],
    );
    final entry2Maps = await db.query(
      'timetable',
      where: 'id = ?',
      whereArgs: [entry2Id],
    );

    if (entry1Maps.isEmpty || entry2Maps.isEmpty) {
      throw Exception('One or both entries not found');
    }

    final entry1 = TimetableEntry.fromMap(entry1Maps.first);
    final entry2 = TimetableEntry.fromMap(entry2Maps.first);

    // Swap teacher names
    await db.update(
      'timetable',
      {'teacherName': entry2.teacherName},
      where: 'id = ?',
      whereArgs: [entry1Id],
    );

    await db.update(
      'timetable',
      {'teacherName': entry1.teacherName},
      where: 'id = ?',
      whereArgs: [entry2Id],
    );
  }

  /// Assign a teacher to a specific entry (for absent teacher replacement)
  Future<int> assignTeacher(int entryId, String newTeacherName) async {
    final db = await database;
    return await db.update(
      'timetable',
      {'teacherName': newTeacherName, 'attendance': 'Present'},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Get available (present) teachers for a specific day
  Future<List<String>> getAvailableTeachers(String day) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'timetable',
      columns: ['teacherName'],
      where: 'day = ? AND attendance = ?',
      whereArgs: [day, 'Present'],
      distinct: true,
    );
    return maps.map((m) => m['teacherName'] as String).toList();
  }

  /// Delete all entries (for re-upload)
  Future<void> deleteAllEntries() async {
    final db = await database;
    await db.delete('timetable');
  }

  /// Delete entries for a specific day
  Future<void> deleteEntriesByDay(String day) async {
    final db = await database;
    await db.delete('timetable', where: 'day = ?', whereArgs: [day]);
  }

  /// Check if timetable data exists
  Future<bool> hasData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM timetable'),
    );
    return count != null && count > 0;
  }
}

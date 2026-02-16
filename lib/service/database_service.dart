import 'dart:async';
import 'package:aiworkflowautomation/model/activity_model.dart';
import 'package:aiworkflowautomation/model/feedback_model.dart';
import 'package:aiworkflowautomation/model/leave_request_model.dart';
import 'package:aiworkflowautomation/model/note_model.dart';
import 'package:aiworkflowautomation/model/notification_model.dart';
import 'package:aiworkflowautomation/model/user_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // 🔹 Real-time stream for notifications
  final StreamController<List<NotificationModel>> _notificationsController =
      StreamController<List<NotificationModel>>.broadcast();

  // 🔹 Real-time stream for stats
  final StreamController<Map<String, int>> _statsController =
      StreamController<Map<String, int>>.broadcast();

  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsController.stream;

  Stream<Map<String, int>> get statsStream => _statsController.stream;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ai_workflow.db');
    return await openDatabase(
      path,
      version: 12, // 🔹 Version bumped to 12 for notifications
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              identifier TEXT UNIQUE,
              password TEXT,
              role TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE leave_requests ADD COLUMN status TEXT DEFAULT 'pending'
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notes(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              subject TEXT,
              teacher TEXT,
              semester TEXT,
              content TEXT
            )
          ''');
        }
        if (oldVersion < 8) {
          // 🔹 Create activities table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS activities(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              teacher TEXT,
              subject TEXT,
              question TEXT,
              date TEXT
            )
          ''');
        }
        if (oldVersion < 9) {
          // 🔹 Create activity_answers table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS activity_answers(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              activity_id INTEGER,
              student_name TEXT,
              answer TEXT,
              date TEXT
            )
          ''');
        }
        if (oldVersion < 10) {
          // 🔹 Add is_bookmarked column to activities
          await db.execute('''
            ALTER TABLE activities ADD COLUMN is_bookmarked INTEGER DEFAULT 0
          ''');
        }
        if (oldVersion < 11) {
          // 🔹 Add is_bookmarked column to notes
          await db.execute('''
            ALTER TABLE notes ADD COLUMN is_bookmarked INTEGER DEFAULT 0
          ''');
        }
        if (oldVersion < 12) {
          // 🔹 Create notifications table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notifications(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              message TEXT,
              date TEXT,
              type TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE leave_requests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        date TEXT,
        type TEXT,
        reason TEXT,
        status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE feedbacks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        content TEXT,
        rating REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        identifier TEXT UNIQUE,
        password TEXT,
        role TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT,
        teacher TEXT,
        semester TEXT,
        content TEXT,
        is_bookmarked INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher TEXT,
        subject TEXT,
        question TEXT,
        date TEXT,
        is_bookmarked INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_answers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id INTEGER,
        student_name TEXT,
        answer TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        message TEXT,
        date TEXT,
        type TEXT
      )
    ''');
  }

  // --- Leave Request Operations ---

  Future<int> insertLeaveRequest(LeaveRequestModel request) async {
    final db = await database;
    return await db.insert('leave_requests', request.toMap());
  }

  Future<List<LeaveRequestModel>> getAllLeaveRequests() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('leave_requests');
    return List.generate(maps.length, (i) {
      return LeaveRequestModel.fromMap(maps[i]);
    });
  }

  Future<List<LeaveRequestModel>> getPendingLeaveRequests() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'leave_requests',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return LeaveRequestModel.fromMap(maps[i]);
    });
  }

  Future<int> updateLeaveRequestStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      'leave_requests',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Feedback Operations ---

  Future<int> insertFeedback(FeedbackModel feedback) async {
    final db = await database;
    return await db.insert('feedbacks', feedback.toMap());
  }

  Future<List<FeedbackModel>> getAllFeedbacks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('feedbacks');
    return List.generate(maps.length, (i) {
      return FeedbackModel.fromMap(maps[i]);
    });
  }

  // --- User / Auth Operations ---

  Future<int> registerUser(UserModel user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    await broadcastStats();
    return id;
  }

  Future<UserModel?> getUser(String identifier) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'identifier = ?',
      whereArgs: [identifier],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  // --- Note Operations ---

  Future<int> insertNote(NoteData note) async {
    final db = await database;
    final id = await db.insert('notes', note.toMap());
    await broadcastStats();
    return id;
  }

  Future<List<NoteData>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return NoteData.fromMap(maps[i]);
    });
  }

  // 🔹 Note Bookmark Operations
  Future<int> updateNoteBookmark(int id, bool isBookmarked) async {
    final db = await database;
    return await db.update(
      'notes',
      {'is_bookmarked': isBookmarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<NoteData>> getBookmarkedNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'is_bookmarked = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return NoteData.fromMap(maps[i]);
    });
  }

  // 🔹 Notification Operations
  Future<int> insertNotification(NotificationModel notification) async {
    final db = await database;
    final id = await db.insert('notifications', notification.toMap());

    // 🔹 Broadcast update
    final updatedNotifications = await getNotifications();
    _notificationsController.add(updatedNotifications);

    if (notification.type == 'substitution') {
      await broadcastStats();
    }

    return id;
  }

  Future<List<NotificationModel>> getNotifications({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'id DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return NotificationModel.fromMap(maps[i]);
    });
  }

  // --- Activity Operations ---

  Future<int> insertActivity(ActivityModel activity) async {
    final db = await database;
    return await db.insert('activities', activity.toMap());
  }

  Future<List<ActivityModel>> getActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return ActivityModel.fromMap(maps[i]);
    });
  }

  // 🔹 Insert Answer
  Future<int> insertActivityAnswer(
    int activityId,
    String studentName,
    String answer,
  ) async {
    final db = await database;
    return await db.insert('activity_answers', {
      'activity_id': activityId,
      'student_name': studentName,
      'answer': answer,
      'date': DateTime.now().toString(),
    });
  }

  Future<List<Map<String, dynamic>>> getActivityAnswers(int activityId) async {
    final db = await database;
    return await db.query(
      'activity_answers',
      where: 'activity_id = ?',
      whereArgs: [activityId],
      orderBy: 'id DESC',
    );
  }

  // 🔹 Bookmark Operations
  Future<int> updateActivityBookmark(int id, bool isBookmarked) async {
    final db = await database;
    return await db.update(
      'activities',
      {'is_bookmarked': isBookmarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ActivityModel>> getBookmarkedActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'is_bookmarked = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return ActivityModel.fromMap(maps[i]);
    });
  }

  // 🔹 Stats Operations
  Future<int> getStudentCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM users WHERE role = 'student'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getNoteCount() async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM notes");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSubstitutionCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM notifications WHERE type = 'substitution'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> broadcastStats() async {
    final stats = {
      'students': await getStudentCount(),
      'notes': await getNoteCount(),
      'substitutions': await getSubstitutionCount(),
    };
    _statsController.add(stats);
  }
}

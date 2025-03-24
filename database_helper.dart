// database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        date TEXT,
        completed INTEGER
      )
    ''');
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    Database db = await database;

    // Convert subtasks to JSON string for storage
    if (task.containsKey('subtasks')) {
      task['subtasks'] = jsonEncode(task['subtasks']);
    } else {
      task['subtasks'] = jsonEncode([]);
    }

    // Convert completed boolean to integer
    task['completed'] = task['completed'] ? 1 : 0;

    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    Database db = await database;
    List<Map<String, dynamic>> tasks = await db.query('tasks');

    // Convert database results to the format your app expects
    return tasks.map((task) {
      // Convert integer back to boolean
      task['completed'] = task['completed'] == 1;

      // Convert JSON string back to list
      if (task['subtasks'] != null) {
        try {
          task['subtasks'] = jsonDecode(task['subtasks']);
        } catch (e) {
          task['subtasks'] = [];
          print("Error decoding subtasks: $e");
        }
      } else {
        task['subtasks'] = [];
      }

      return task;
    }).toList();
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    Database db = await database;

    // Prepare task for database storage
    Map<String, dynamic> taskToUpdate = Map.from(task);

    // Convert subtasks to JSON string
    if (taskToUpdate.containsKey('subtasks')) {
      taskToUpdate['subtasks'] = jsonEncode(taskToUpdate['subtasks']);
    }

    // Convert completed boolean to integer
    taskToUpdate['completed'] = taskToUpdate['completed'] ? 1 : 0;

    return await db.update(
      'tasks',
      taskToUpdate,
      where: 'id = ?',
      whereArgs: [task['id']],
    );
  }

  Future<int> deleteTask(int id) async {
    Database db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Budget methods
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    Database db = await database;
    return await db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getExpenses(String taskId) async {
    Database db = await database;
    return await db.query(
      'expenses',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> deleteExpense(int id) async {
    Database db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertIncome(Map<String, dynamic> income) async {
    Database db = await database;
    return await db.insert('income', income);
  }

  Future<List<Map<String, dynamic>>> getIncome(String taskId) async {
    Database db = await database;
    return await db.query(
      'income',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> deleteIncome(int id) async {
    Database db = await database;
    return await db.delete(
      'income',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Method to get active task count
  Future<int> getActiveTaskCount() async {
    Database db = await database;
    var result = await db
        .rawQuery('SELECT COUNT(*) as count FROM tasks WHERE completed = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

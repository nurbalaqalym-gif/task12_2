import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StudentPage(),
    );
  }
}

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final TextEditingController _nameController = TextEditingController();

  Database? _database;
  List<Map<String, dynamic>> _students = [];
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    _database = await openDatabase(
      join(dbPath, 'students.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
      },
    );

    await _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await _database!.query('students', orderBy: 'id DESC');

    if (!mounted) return;

    setState(() {
      _students = students;
    });
  }

  Future<void> _addStudent() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) return;

    await _database!.insert('students', {'name': name});

    _nameController.clear();
    await _loadStudents();
  }

  Future<void> _updateStudent() async {
    final name = _nameController.text.trim();

    if (name.isEmpty || _editingId == null) return;

    await _database!.update(
      'students',
      {'name': name},
      where: 'id = ?',
      whereArgs: [_editingId],
    );

    _cancelUpdate();
    await _loadStudents();
  }

  Future<void> _deleteStudent(int id) async {
    await _database!.delete('students', where: 'id = ?', whereArgs: [id]);

    if (_editingId == id) {
      _cancelUpdate();
    }

    await _loadStudents();
  }

  void _startUpdate(Map<String, dynamic> student) {
    setState(() {
      _editingId = student['id'] as int;
      _nameController.text = student['name'] as String;
    });
  }

  void _cancelUpdate() {
    setState(() {
      _editingId = null;
      _nameController.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingId != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'SQLite CRUD Demo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 30, color: Colors.black),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isEditing ? _updateStudent : _addStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(isEditing ? 'UPDATE' : 'ADD'),
              ),
              if (isEditing) ...[
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _cancelUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('CANCEL UPDATE'),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          Container(
            height: 54,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'NAME',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'DELETE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _students.isEmpty
                ? const Center(
                    child: Text(
                      'No students yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final id = student['id'] as int;
                      final name = student['name'] as String;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.only(left: 32),
                            title: Text(
                              name,
                              style: const TextStyle(fontSize: 16),
                            ),
                            onTap: () => _startUpdate(student),
                            trailing: SizedBox(
                              width: 100,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _deleteStudent(id),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

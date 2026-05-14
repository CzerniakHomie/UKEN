import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'dart:math';

import 'task_repository.dart';
import 'task_api_service.dart';
import 'task_local_database.dart';
import 'task_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("tasks");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KrakFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";
  late Future<List<Task>> tasksFuture;

  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    final tasks = TaskLocalDatabase.getTasks();
    updateCounters(tasks);
    return tasks;
  }

  void updateCounters(List<Task> tasks) {
    setState(() {
      allTasksCount = tasks.length;
      doneTasksCount = tasks.where((task) => task.done).length;
      todoTasksCount = tasks.where((task) => !task.done).length;
    });
  }

  void refreshScreen() {
    setState(() {
      tasksFuture = loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("KrakFlow", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Potwierdzenie"),
                  content: const Text("Czy na pewno chcesz usunąć wszystkie zadania?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Anuluj"),
                    ),
                    TextButton(
                      onPressed: () async {
                        await TaskLocalDatabase.deleteAllTasks();
                        refreshScreen();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Wszystkie zadania zostały usunięte")),
                          );
                        }
                      },
                      child: const Text("Usuń"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Błąd: ${snapshot.error}"));
          }

          final tasks = snapshot.data ?? [];
          List<Task> filteredTasks = tasks;

          if (selectedFilter == "wykonane") {
            filteredTasks = tasks.where((task) => task.done).toList();
          } else if (selectedFilter == "do zrobienia") {
            filteredTasks = tasks.where((task) => !task.done).toList();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Masz dziś $allTasksCount zadania. Wykonano: $doneTasksCount",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => selectedFilter = "wszystkie"),
                      child: Text("Wszystkie",
                          style: TextStyle(color: selectedFilter == "wszystkie" ? Colors.blue : Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => selectedFilter = "do zrobienia"),
                      child: Text("Do zrobienia",
                          style: TextStyle(color: selectedFilter == "do zrobienia" ? Colors.blue : Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => selectedFilter = "wykonane"),
                      child: Text("Wykonane",
                          style: TextStyle(color: selectedFilter == "wykonane" ? Colors.blue : Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Dismissible(
                        key: ObjectKey(task),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await TaskLocalDatabase.deleteTask(task.id);
                          refreshScreen();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Zadanie usunięte")),
                            );
                          }
                        },
                        child: TaskCard(
                          task: task,
                          onChanged: (value) async {
                            final updatedTask = Task(
                              id: task.id,
                              title: task.title,
                              deadline: task.deadline,
                              priority: task.priority,
                              done: value ?? false,
                            );
                            await TaskLocalDatabase.updateTask(updatedTask);
                            refreshScreen();
                          },
                          onTap: () async {
                            final Task? updatedTask = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTaskScreen(task: task),
                              ),
                            );
                            if (updatedTask != null) {
                              await TaskLocalDatabase.updateTask(updatedTask);
                              refreshScreen();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );

          if (newTask != null) {
            await TaskLocalDatabase.addTask(newTask);
            refreshScreen();
          }
        },
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});
  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  final priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowe zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł")),
            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin")),
            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Navigator.pop(context, Task(
                    id: Random().nextInt(1000000), //losowe id dla nowego zadania
                    title: titleController.text,
                    deadline: deadlineController.text.isEmpty ? "brak" : deadlineController.text,
                    priority: priorityController.text.isEmpty ? "normalny" : priorityController.text,
                    done: false,
                  ));
                }
              },
              child: const Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;
  EditTaskScreen({super.key, required this.task});

  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  final priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    titleController.text = task.title;
    deadlineController.text = task.deadline;
    priorityController.text = task.priority;

    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł")),
            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin")),
            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, Task(
                  id: task.id,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: task.done,
                ));
              },
              child: const Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onChanged, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.done,
          onChanged: onChanged,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : TextDecoration.none,
            color: task.done ? Colors.black54 : Colors.black,
          ),
        ),
        subtitle: Text("Termin: ${task.deadline} | Priorytet: ${task.priority}"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
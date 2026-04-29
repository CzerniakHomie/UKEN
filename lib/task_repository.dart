class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

//lista zadan
class TaskRepository {
  static List<Task> tasks = [
    Task(title: "Zrobić zakupy spożywcze", deadline: "dzisiaj", done: true, priority: "wysoki"),
    Task(title: "Napisać sprawozdsanie z Lab 4", deadline: "jutro", done: false, priority: "wysoki"),
    Task(title: "Umyć samochod", deadline: "sobota", done: false, priority: "niski"),
    Task(title: "Przygotować się do kolokwium", deadline: "wtorek", done: false, priority: "średni"),
  ];
}
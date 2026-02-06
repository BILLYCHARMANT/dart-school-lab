// Q17: In main(), call `loadStudents()`, use await, and print the number of students loaded.

import 'dart:async';

class Student {
  String name;
  int age;

  Student(this.name, this.age);
}

Future<List<Student>> loadStudents() async {
  await Future.delayed(Duration(seconds: 2));
  return [
    Student('Philippe Mugisha', 18),
    Student('Billy Charmant', 19),
    Student('Mulisa Sana', 20),
  ];
}

void main() async {
  List<Student> students = await loadStudents();
  print('Number of students loaded: ${students.length}');
}

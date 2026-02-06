// Q16: Write an async function `loadStudents()` that waits 2 seconds and returns the list of students.

import 'dart:async';

class Student {
  String name;
  int age;

  Student(this.name, this.age);
}

Future<List<Student>> loadStudents() async {
  await Future.delayed(Duration(seconds: 2));
  return [
    Student('Tom Sangwa', 18),
    Student('Uma Patel', 19),
    Student('Victor Kwizera', 20),
  ];
}

void main() async {
  List<Student> students = await loadStudents();
}

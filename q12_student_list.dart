// Q12: Create a List storing multiple `Student` objects. Add 3 students.

class Student {
  String name;
  int age;

  Student(this.name, this.age);
}

void main() {
  List<Student> students = [];
  students.add(Student('Grace Taylor', 18));
  students.add(Student('Henry Brown', 19));
  students.add(Student('Ivy Johnson', 20));
}

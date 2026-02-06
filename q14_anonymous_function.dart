// Q14: Use an anonymous function to print all student names from the list.

class Student {
  String name;
  int age;

  Student(this.name, this.age);
}

void main() {
  List<Student> students = [
    Student('Mary White', 18),
    Student('Nick Green', 19),
    Student('Olivia Black', 20),
  ];
  
  students.forEach((student) {
    print('${student.name}');
  });
}

// Q9: Make `Student` implement `Registrable` and implement `registerCourse` to print the student name and course.

abstract class Registrable {
  void registerCourse(String courseName);
}

class Student implements Registrable {
  String name;
  int age;

  Student(this.name, this.age);

  @override
  void registerCourse(String courseName) {
    print('Student: $name');
    print('Course: $courseName');
  }
}

void main() {
  Student student = Student('Emma Watson', 20);
  student.registerCourse('Computer Science 101');
}

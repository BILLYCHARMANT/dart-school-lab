// Q19: Create a new mixin `NotificationMixin` that prints a message when a student is registered to a course. Apply it to `Student`.

abstract class Registrable {
  void registerCourse(String courseName);
}

mixin NotificationMixin {
  void notifyRegistration(String studentName, String courseName) {
    print('Notification: $studentName has been registered to $courseName');
  }
}

class Student with NotificationMixin implements Registrable {
  String name;
  int age;

  Student(this.name, this.age);

  @override
  void registerCourse(String courseName) {
    notifyRegistration(name, courseName);
  }
}

void main() {
  Student student = Student('Zoe Martinez', 21);
  student.registerCourse('Data Structures');
}

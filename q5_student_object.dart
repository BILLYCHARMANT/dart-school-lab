// Q5: Create an object of `Student` and print the student's name and age.

class Student {
  String name;
  int age;

  Student(this.name, this.age);
}

void main() {
  Student student = Student('Bob Wilson', 21);
  print('Name: ${student.name}');
  print('Age: ${student.age}');
}

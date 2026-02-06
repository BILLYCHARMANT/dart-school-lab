// Q4: Create a class named `Student` with `name` and `age`, and a constructor to initialize these values.

class Student {
  String name;
  int age;

  Student(this.name, this.age);
}

void main() {
  Student student = Student('Alice Brown', 18);
}

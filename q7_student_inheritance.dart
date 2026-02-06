// Q7: Make `Student` inherit from `Person` and call `introduce()` from a `Student` object.

class Person {
  String name;

  Person(this.name);

  void introduce() {
    print('Hello, my name is $name');
  }
}

class Student extends Person {
  int age;

  Student(String name, this.age) : super(name);
}

void main() {
  Student student = Student('Billy Charmant', 19);
  student.introduce();
}

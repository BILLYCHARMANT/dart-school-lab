// Q6: Create a class `Person` with a variable `name` and a function `introduce()` that prints the name.

class Person {
  String name;

  Person(this.name);

  void introduce() {
    print('Hello, my name is $name');
  }
}

void main() {
  Person person = Person('Charlie Davis');
  person.introduce();
}

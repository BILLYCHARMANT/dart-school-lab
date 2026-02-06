// Q2: Write a function named `createStudent` that uses named parameters (`name` and `age`) and prints the student details.

void createStudent({required String name, required int age}) {
  print('Name: $name');
  print('Age: $age');
}

void main() {
  createStudent(name: 'John Doe', age: 20);
}

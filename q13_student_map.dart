// Q13: Create a Map where the key is student ID and value is a `Student`. Print all student names.

class Student {
  String name;
  int age;

  Student(this.name, this.age);
}

void main() {
  Map<String, Student> studentMap = {
    'ST001': Student('Jack Billy', 18),
    'ST002': Student('Kate Davis', 19),
    'ST003': Student('Luke Philippe', 21),
  };
  
  studentMap.forEach((id, student) {
    print('${student.name}');
  });
}

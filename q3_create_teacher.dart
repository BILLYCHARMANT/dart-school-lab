// Q3: Write a function named `createTeacher` with one required parameter `name` and one optional parameter `subject`. If subject is not provided, print 'Subject not assigned'.

void createTeacher(String name, [String? subject]) {
  if (subject != null) {
    print('Subject: $subject');
  } else {
    print('Subject not assigned');
  }
}

void main() {
  createTeacher('Dr. Smith', 'Mathematics');
  createTeacher('Prof. Johnson');
}

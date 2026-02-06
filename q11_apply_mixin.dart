// Q11: Apply `AttendanceMixin` to `Student`. Mark attendance 3 times and print the attendance.

mixin AttendanceMixin {
  int _attendanceCount = 0;

  void markAttendance() {
    _attendanceCount++;
  }

  int get attendanceCount => _attendanceCount;
}

class Student with AttendanceMixin {
  String name;
  int age;

  Student(this.name, this.age);
}

void main() {
  Student student = Student('Billy Charmant', 22);
  student.markAttendance();
  student.markAttendance();
  student.markAttendance();
  print('Attendance: ${student.attendanceCount}');
}

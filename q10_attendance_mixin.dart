// Q10: Create a mixin `AttendanceMixin` that stores an attendance counter and has a function `markAttendance()` to increase attendance.

mixin AttendanceMixin {
  int _attendanceCount = 0;

  void markAttendance() {
    _attendanceCount++;
    
  }

  int get attendanceCount => _attendanceCount;
  
}

void main() {  
}

import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';

class TimetableEngine {
  static List<Task> generate({
    required double dailyHours,
    required List<Subject> subjects,
    required TimeOfDay wakeUpTime,
    required TimeOfDay lunchTime,
    required TimeOfDay dinnerTime,
    required int restMins,
  }) {
    List<Task> generatedTasks = [];
    final now = DateTime.now();
    
    // 1. Add Wake up task
    DateTime startTime = DateTime(now.year, now.month, now.day, wakeUpTime.hour, wakeUpTime.minute);
    DateTime wakeUpEnd = startTime.add(const Duration(minutes: 30));
    
    generatedTasks.add(Task(
      id: 'wakeup_${now.millisecondsSinceEpoch}',
      title: 'Wake up + morning routine',
      startTime: startTime,
      endTime: wakeUpEnd,
      colorIndex: 0,
      isCompleted: false,
    ));

    DateTime currentTime = wakeUpEnd;
    
    // Meal times as DateTime
    DateTime lunchDT = DateTime(now.year, now.month, now.day, lunchTime.hour, lunchTime.minute);
    DateTime dinnerDT = DateTime(now.year, now.month, now.day, dinnerTime.hour, dinnerTime.minute);

    double totalMinutesAllowed = dailyHours * 60;
    double currentStudyMinutes = 0;

    final activeSubjects = subjects.where((s) => s.isActive).toList();
    if (activeSubjects.isEmpty) return generatedTasks;

    int subjectIndex = 0;
    
    while (currentStudyMinutes < totalMinutesAllowed && generatedTasks.length < 25) {
      final subject = activeSubjects[subjectIndex % activeSubjects.length];
      
      // Check for lunch
      if (currentTime.isBefore(lunchDT) && currentTime.add(Duration(minutes: subject.durationMinutes)).isAfter(lunchDT)) {
        DateTime lunchEnd = lunchDT.add(const Duration(minutes: 60));
        generatedTasks.add(Task(
          id: 'lunch_${now.millisecondsSinceEpoch}',
          title: 'Lunch Break',
          startTime: lunchDT,
          endTime: lunchEnd,
          colorIndex: 3,
        ));
        currentTime = lunchEnd;
      }
      
      // Check for dinner
      if (currentTime.isBefore(dinnerDT) && currentTime.add(Duration(minutes: subject.durationMinutes)).isAfter(dinnerDT)) {
        DateTime dinnerEnd = dinnerDT.add(const Duration(minutes: 60));
        generatedTasks.add(Task(
          id: 'dinner_${now.millisecondsSinceEpoch}',
          title: 'Dinner Break',
          startTime: dinnerDT,
          endTime: dinnerEnd,
          colorIndex: 4,
        ));
        currentTime = dinnerEnd;
      }

      if (currentTime.day != now.day) break;

      DateTime studyEnd = currentTime.add(Duration(minutes: subject.durationMinutes));

      generatedTasks.add(Task(
        id: 'study_${now.millisecondsSinceEpoch}_$subjectIndex',
        title: subject.name,
        startTime: currentTime,
        endTime: studyEnd,
        colorIndex: activeSubjects.indexOf(subject) % 7,
        isCompleted: false,
      ));

      currentStudyMinutes += subject.durationMinutes;
      currentTime = studyEnd;

      // Add Break Task
      if (currentStudyMinutes < totalMinutesAllowed) {
        DateTime breakEnd = currentTime.add(Duration(minutes: restMins));
        generatedTasks.add(Task(
          id: 'break_${now.millisecondsSinceEpoch}_$subjectIndex',
          title: restMins > 20 ? 'Break' : 'Short break',
          startTime: currentTime,
          endTime: breakEnd,
          colorIndex: 1,
        ));
        currentTime = breakEnd;
      }
      
      subjectIndex++;
    }

    return generatedTasks;
  }
}

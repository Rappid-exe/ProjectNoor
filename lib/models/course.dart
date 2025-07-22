class Course {
  final String id;
  final String name;
  final String category;
  final String duration;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String objectives;
  final Map<String, bool> completionStatus; // lessonId -> isCompleted

  Course({
    required this.id,
    required this.name,
    required this.category,
    required this.duration,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.objectives,
    required this.completionStatus,
  });

  // Calculate progress percentage
  double getProgressPercentage() {
    if (completionStatus.isEmpty) return 0.0;
    
    int totalLessons = completionStatus.length;
    int completedLessons = 0;
    
    completionStatus.forEach((lessonId, isCompleted) {
      if (isCompleted) completedLessons++;
    });
    
    return totalLessons > 0 ? (completedLessons / totalLessons) : 0.0;
  }
}
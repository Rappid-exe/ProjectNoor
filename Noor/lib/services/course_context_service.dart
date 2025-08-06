import 'dart:async';
import 'package:flutter/foundation.dart';

import 'course_service.dart';
import '../models/course.dart';

/// Service for providing course-aware context to AI chat interactions
class CourseContextService {
  static CourseContextService? _instance;
  static CourseContextService get instance => _instance ??= CourseContextService._();
  
  CourseContextService._();
  
  /// Create a new instance for testing
  static CourseContextService createForTesting() => CourseContextService._();

  final CourseService _courseService = CourseService();
  String? _currentCourseId;
  String? _currentLessonId;
  Map<String, dynamic> _userLearningProfile = {};

  /// Set the current course context for AI interactions
  void setCurrentCourse(String courseId, {String? lessonId}) {
    _currentCourseId = courseId;
    _currentLessonId = lessonId;
    
    if (kDebugMode) {
      print('CourseContextService: Set current course to $courseId, lesson: $lessonId');
    }
  }

  /// Clear the current course context
  void clearCurrentCourse() {
    _currentCourseId = null;
    _currentLessonId = null;
    
    if (kDebugMode) {
      print('CourseContextService: Cleared current course context');
    }
  }

  /// Get the current course context
  String? get currentCourseId => _currentCourseId;
  String? get currentLessonId => _currentLessonId;

  /// Update user learning profile for better AI recommendations
  void updateLearningProfile(Map<String, dynamic> profile) {
    _userLearningProfile.addAll(profile);
    
    if (kDebugMode) {
      print('CourseContextService: Updated learning profile: $profile');
    }
  }

  /// Get user learning profile
  Map<String, dynamic> get learningProfile => Map.unmodifiable(_userLearningProfile);

  /// Generate course-aware context for AI chat
  Future<Map<String, dynamic>> generateChatContext() async {
    try {
      final context = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'userProfile': _userLearningProfile,
      };

      // Add current course information if available
      if (_currentCourseId != null) {
        final currentCourse = await _getCurrentCourse();
        if (currentCourse != null) {
          context['currentCourse'] = {
            'id': currentCourse.id,
            'name': currentCourse.name,
            'category': currentCourse.category,
            'description': currentCourse.description,
            'objectives': currentCourse.objectives,
            'progress': currentCourse.getProgressPercentage(),
            'currentLesson': _currentLessonId,
            'completionStatus': currentCourse.completionStatus,
          };

          // Add lesson-specific context
          if (_currentLessonId != null) {
            context['currentLesson'] = {
              'id': _currentLessonId,
              'isCompleted': currentCourse.completionStatus[_currentLessonId] ?? false,
              'course': currentCourse.name,
            };
          }
        }
      }

      // Add overall learning progress
      final allCourses = await _courseService.getUserCourses().first;
      context['overallProgress'] = await _calculateOverallProgress(allCourses);

      // Add learning recommendations context
      context['recommendations'] = await _generateRecommendationsContext(allCourses);

      return context;
    } catch (e) {
      if (kDebugMode) {
        print('CourseContextService: Error generating chat context: $e');
      }
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': 'Failed to generate course context',
      };
    }
  }

  /// Get the current course object
  Future<Course?> _getCurrentCourse() async {
    if (_currentCourseId == null) return null;
    
    try {
      final allCourses = await _courseService.getUserCourses().first;
      return allCourses.firstWhere(
        (course) => course.id == _currentCourseId,
        orElse: () => throw StateError('Course not found'),
      );
    } catch (e) {
      if (kDebugMode) {
        print('CourseContextService: Error getting current course: $e');
      }
      return null;
    }
  }

  /// Calculate overall learning progress across all courses
  Future<Map<String, dynamic>> _calculateOverallProgress(List<Course> courses) async {
    if (courses.isEmpty) {
      return {
        'totalCourses': 0,
        'completedCourses': 0,
        'inProgressCourses': 0,
        'averageProgress': 0.0,
      };
    }

    int completedCourses = 0;
    int inProgressCourses = 0;
    double totalProgress = 0.0;

    for (final course in courses) {
      final progress = course.getProgressPercentage();
      totalProgress += progress;
      
      if (progress >= 1.0) {
        completedCourses++;
      } else if (progress > 0.0) {
        inProgressCourses++;
      }
    }

    return {
      'totalCourses': courses.length,
      'completedCourses': completedCourses,
      'inProgressCourses': inProgressCourses,
      'notStartedCourses': courses.length - completedCourses - inProgressCourses,
      'averageProgress': totalProgress / courses.length,
    };
  }

  /// Generate recommendations context for AI
  Future<Map<String, dynamic>> _generateRecommendationsContext(List<Course> courses) async {
    final context = <String, dynamic>{};
    
    // Find courses that need attention
    final strugglingCourses = <Map<String, dynamic>>[];
    final readyForNext = <Map<String, dynamic>>[];
    
    for (final course in courses) {
      final progress = course.getProgressPercentage();
      
      // Courses with low progress that were started
      if (progress > 0 && progress < 0.3) {
        strugglingCourses.add({
          'id': course.id,
          'name': course.name,
          'progress': progress,
          'category': course.category,
        });
      }
      
      // Courses ready for next lesson
      if (progress > 0 && progress < 1.0) {
        final nextLesson = _findNextIncompleteLesson(course);
        if (nextLesson != null) {
          readyForNext.add({
            'id': course.id,
            'name': course.name,
            'progress': progress,
            'nextLesson': nextLesson,
            'category': course.category,
          });
        }
      }
    }
    
    context['strugglingCourses'] = strugglingCourses;
    context['readyForNext'] = readyForNext;
    
    // Add learning patterns
    context['learningPatterns'] = _analyzeLearningPatterns(courses);
    
    return context;
  }

  /// Find the next incomplete lesson in a course
  String? _findNextIncompleteLesson(Course course) {
    for (final entry in course.completionStatus.entries) {
      if (!entry.value) {
        return entry.key;
      }
    }
    return null;
  }

  /// Analyze learning patterns from course data
  Map<String, dynamic> _analyzeLearningPatterns(List<Course> courses) {
    final patterns = <String, dynamic>{};
    
    // Analyze preferred categories
    final categoryProgress = <String, List<double>>{};
    for (final course in courses) {
      categoryProgress.putIfAbsent(course.category, () => []).add(course.getProgressPercentage());
    }
    
    final preferredCategories = <String>[];
    categoryProgress.forEach((category, progressList) {
      final avgProgress = progressList.reduce((a, b) => a + b) / progressList.length;
      if (avgProgress > 0.5) {
        preferredCategories.add(category);
      }
    });
    
    patterns['preferredCategories'] = preferredCategories;
    patterns['categoryProgress'] = categoryProgress.map((k, v) => 
      MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    
    // Analyze completion patterns
    final completionRates = courses.map((c) => c.getProgressPercentage()).toList();
    completionRates.sort();
    
    patterns['medianProgress'] = completionRates.isNotEmpty 
      ? completionRates[completionRates.length ~/ 2] 
      : 0.0;
    
    return patterns;
  }

  /// Generate a summary of current learning state for AI context
  Future<String> generateLearningStateSummary() async {
    try {
      final context = await generateChatContext();
      final buffer = StringBuffer();
      
      buffer.writeln('=== Current Learning Context ===');
      
      // Current course info
      if (context['currentCourse'] != null) {
        final course = context['currentCourse'] as Map<String, dynamic>;
        buffer.writeln('Currently studying: ${course['name']} (${course['category']})');
        buffer.writeln('Course progress: ${(course['progress'] * 100).toInt()}%');
        
        if (context['currentLesson'] != null) {
          final lesson = context['currentLesson'] as Map<String, dynamic>;
          buffer.writeln('Current lesson: ${lesson['id']} (${lesson['isCompleted'] ? 'Completed' : 'In Progress'})');
        }
        
        buffer.writeln('Course objectives: ${course['objectives']}');
      } else {
        buffer.writeln('No current course selected');
      }
      
      // Overall progress
      if (context['overallProgress'] != null) {
        final progress = context['overallProgress'] as Map<String, dynamic>;
        buffer.writeln('\n=== Overall Learning Progress ===');
        buffer.writeln('Total courses: ${progress['totalCourses']}');
        buffer.writeln('Completed: ${progress['completedCourses']}');
        buffer.writeln('In progress: ${progress['inProgressCourses']}');
        buffer.writeln('Average progress: ${(progress['averageProgress'] * 100).toInt()}%');
      }
      
      // Recommendations
      if (context['recommendations'] != null) {
        final recommendations = context['recommendations'] as Map<String, dynamic>;
        
        if (recommendations['readyForNext'] != null) {
          final ready = recommendations['readyForNext'] as List<dynamic>;
          if (ready.isNotEmpty) {
            buffer.writeln('\n=== Ready for Next Lessons ===');
            for (final course in ready.take(3)) {
              buffer.writeln('- ${course['name']}: Lesson ${course['nextLesson']}');
            }
          }
        }
        
        if (recommendations['strugglingCourses'] != null) {
          final struggling = recommendations['strugglingCourses'] as List<dynamic>;
          if (struggling.isNotEmpty) {
            buffer.writeln('\n=== Courses Needing Attention ===');
            for (final course in struggling.take(2)) {
              buffer.writeln('- ${course['name']}: ${(course['progress'] * 100).toInt()}% progress');
            }
          }
        }
      }
      
      return buffer.toString();
    } catch (e) {
      if (kDebugMode) {
        print('CourseContextService: Error generating learning state summary: $e');
      }
      return 'Unable to generate learning context summary';
    }
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    _currentCourseId = null;
    _currentLessonId = null;
    _userLearningProfile.clear();
    
    if (kDebugMode) {
      print('CourseContextService: Disposed');
    }
  }
}
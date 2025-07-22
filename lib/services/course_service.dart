import 'package:noor/models/course.dart';

class CourseService {
  // In-memory list of courses for offline use.
  // This will be replaced by a local database later.
  final List<Course> _courses = [
    Course(
      id: '1',
      name: 'Basic Literacy (Dari)',
      category: 'Language',
      duration: '8 weeks',
      description: 'Learn the fundamentals of reading and writing in the Dari language.',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 46)),
      objectives: 'Recognize the alphabet, form simple words, and read basic sentences.',
      completionStatus: {'L1': true, 'L2': true, 'L3': false, 'L4': false},
    ),
    Course(
      id: '2',
      name: 'Introduction to Mathematics',
      category: 'STEM',
      duration: '12 weeks',
      description: 'Covering basic arithmetic, including addition, subtraction, multiplication, and division.',
      startDate: DateTime.now().subtract(const Duration(days: 20)),
      endDate: null, // Ongoing course
      objectives: 'Solve basic arithmetic problems and understand number concepts.',
      completionStatus: {'L1': true, 'L2': true, 'L3': true, 'L4': false, 'L5': false},
    ),
     Course(
      id: '3',
      name: 'Health and Hygiene',
      category: 'Life Skills',
      duration: '4 weeks',
      description: 'Essential health practices for self and family, focusing on hygiene and sanitation.',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 23)),
      objectives: 'Understand the importance of clean water, handwashing, and basic first-aid.',
      completionStatus: {'L1': true, 'L2': false},
    ),
    Course(
      id: '4',
      name: 'English for Beginners',
      category: 'Language',
      duration: '10 weeks',
      description: 'An introduction to the English language, focusing on conversational skills and basic grammar.',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 68)),
      objectives: 'Hold a simple conversation, understand common phrases, and write basic sentences.',
      completionStatus: {'L1': true, 'L2': false, 'L3': false},
    ),
    Course(
      id: '5',
      name: 'General Science',
      category: 'STEM',
      duration: '16 weeks',
      description: 'Explore fundamental concepts in biology, chemistry, and physics.',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 112)),
      objectives: 'Understand the scientific method, basic cell structure, and the states of matter.',
      completionStatus: {'L1': false, 'L2': false, 'L3': false, 'L4': false, 'L5': false},
    ),
  ];

  // Get all available courses
  Stream<List<Course>> getUserCourses() {
    // Return the in-memory list as a stream to mimic network latency
    return Stream.value(_courses);
  }

  // In-memory update. This is not persistent.
  Future<void> updateLessonCompletion(String courseId, String lessonId, bool isCompleted) async {
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex != -1) {
      _courses[courseIndex].completionStatus[lessonId] = isCompleted;
    }
  }
}
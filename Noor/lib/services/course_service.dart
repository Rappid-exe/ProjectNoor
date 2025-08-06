import 'package:noor/models/course.dart';
import 'package:noor/models/lesson.dart';
// import 'package:noor/services/course_content_generator.dart';

class CourseService {
  // final CourseContentGenerator _contentGenerator = CourseContentGenerator();
  
  // In-memory list of courses with rich content for demo
  List<Course> _courses = [];
  bool _isInitialized = false;

  // Initialize courses with AI-generated content
  Future<void> initializeCourses() async {
    if (_isInitialized) return;

    _courses = await _generateDemoCoursesWithContent();
    _isInitialized = true;
  }

  // Get all available courses
  Stream<List<Course>> getUserCourses() async* {
    if (!_isInitialized) {
      await initializeCourses();
    }
    yield _courses;
  }

  // Get a specific course by ID
  Future<Course?> getCourseById(String courseId) async {
    if (!_isInitialized) {
      await initializeCourses();
    }
    
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  // Get lessons for a specific course
  Future<List<Lesson>> getCourseLessons(String courseId) async {
    final course = await getCourseById(courseId);
    return course?.lessons ?? [];
  }

  // Get a specific lesson
  Future<Lesson?> getLesson(String courseId, String lessonId) async {
    final course = await getCourseById(courseId);
    if (course == null) return null;
    
    try {
      return course.lessons.firstWhere((lesson) => lesson.id == lessonId);
    } catch (e) {
      return null;
    }
  }

  // Update lesson completion status
  Future<void> updateLessonCompletion(String courseId, String lessonId, bool isCompleted) async {
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex != -1) {
      _courses[courseIndex].completionStatus[lessonId] = isCompleted;
      
      // Update the lesson object as well
      final lessonIndex = _courses[courseIndex].lessons.indexWhere((l) => l.id == lessonId);
      if (lessonIndex != -1) {
        _courses[courseIndex].lessons[lessonIndex] = 
            _courses[courseIndex].lessons[lessonIndex].copyWith(isCompleted: isCompleted);
      }
    }
  }

  // Generate practice questions for a lesson using AI
  Future<List<PracticeQuestion>> generatePracticeQuestions(String courseId, String lessonId) async {
    final lesson = await getLesson(courseId, lessonId);
    if (lesson == null) return [];

    // return await _contentGenerator.generatePracticeQuestions(
    //   lessonContent: lesson.content,
    //   lessonTitle: lesson.title,
    //   questionCount: 3,
    // );
    return [];
  }

  // Create demo courses with rich AI-generated content
  Future<List<Course>> _generateDemoCoursesWithContent() async {
    final courses = <Course>[];

    // Course 1: Basic Literacy (Dari) - With actual lessons
    final dariLessons = await _generateLessonsForCourse(
      courseTitle: 'Basic Literacy (Dari)',
      courseCategory: 'Language',
      lessonTitles: [
        'Introduction to Dari Alphabet',
        'Basic Letter Recognition',
        'Simple Word Formation',
        'Reading Short Sentences',
        'Writing Practice',
        'Common Daily Vocabulary',
      ],
    );

    courses.add(Course(
      id: '1',
      name: 'Basic Literacy (Dari)',
      category: 'Language',
      duration: '8 weeks',
      description: 'Learn the fundamentals of reading and writing in the Dari language with interactive lessons and practice exercises.',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 46)),
      objectives: 'Recognize the Dari alphabet, form simple words, read basic sentences, and write common vocabulary.',
      completionStatus: {'L1': true, 'L2': true, 'L3': false, 'L4': false, 'L5': false, 'L6': false},
      lessons: dariLessons,
      difficulty: 'beginner',
      prerequisites: [],
    ));

    // Course 2: Introduction to Mathematics - With actual lessons
    final mathLessons = await _generateLessonsForCourse(
      courseTitle: 'Introduction to Mathematics',
      courseCategory: 'STEM',
      lessonTitles: [
        'Understanding Numbers 1-10',
        'Basic Addition Concepts',
        'Simple Subtraction',
        'Introduction to Multiplication',
        'Basic Division',
        'Solving Word Problems',
        'Money and Counting',
      ],
    );

    courses.add(Course(
      id: '2',
      name: 'Introduction to Mathematics',
      category: 'STEM',
      duration: '12 weeks',
      description: 'Master basic arithmetic operations with practical examples and real-world applications.',
      startDate: DateTime.now().subtract(const Duration(days: 20)),
      endDate: null,
      objectives: 'Solve basic arithmetic problems, understand number concepts, and apply math in daily life.',
      completionStatus: {'L1': true, 'L2': true, 'L3': true, 'L4': false, 'L5': false, 'L6': false, 'L7': false},
      lessons: mathLessons,
      difficulty: 'beginner',
      prerequisites: [],
    ));

    // Course 3: Health and Hygiene - With actual lessons
    final healthLessons = await _generateLessonsForCourse(
      courseTitle: 'Health and Hygiene',
      courseCategory: 'Life Skills',
      lessonTitles: [
        'Importance of Personal Hygiene',
        'Proper Handwashing Techniques',
        'Safe Water and Food Practices',
        'Basic First Aid Skills',
      ],
    );

    courses.add(Course(
      id: '3',
      name: 'Health and Hygiene',
      category: 'Life Skills',
      duration: '4 weeks',
      description: 'Essential health practices for self and family, focusing on hygiene, sanitation, and basic medical knowledge.',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 23)),
      objectives: 'Understand the importance of hygiene, learn proper handwashing, practice safe food handling, and apply basic first aid.',
      completionStatus: {'L1': true, 'L2': false, 'L3': false, 'L4': false},
      lessons: healthLessons,
      difficulty: 'beginner',
      prerequisites: [],
    ));

    return courses;
  }

  // Generate lessons for a course using AI
  Future<List<Lesson>> _generateLessonsForCourse({
    required String courseTitle,
    required String courseCategory,
    required List<String> lessonTitles,
  }) async {
    final lessons = <Lesson>[];
    final previousLessons = <String>[];

    for (int i = 0; i < lessonTitles.length; i++) {
      final lessonId = 'L${i + 1}';
      final lessonTitle = lessonTitles[i];

      try {
        // final lesson = await _contentGenerator.generateLesson(
        //   courseTitle: courseTitle,
        //   courseCategory: courseCategory,
        //   lessonTitle: lessonTitle,
        //   lessonId: lessonId,
        //   previousLessons: previousLessons,
        // );

        // Generate practice questions for the lesson
        // final practiceQuestions = await _contentGenerator.generatePracticeQuestions(
        //   lessonContent: lesson.content,
        //   lessonTitle: lesson.title,
        //   questionCount: 2,
        // );
        
        // Fallback lesson
        final lesson = Lesson(
          id: lessonId,
          title: lessonTitle,
          description: 'Learn about $lessonTitle',
          content: 'This lesson covers the important concepts of $lessonTitle. You will learn practical skills and knowledge that you can apply in your daily life.',
          learningObjectives: ['Understand $lessonTitle', 'Apply knowledge practically'],
          keyTerms: ['$lessonTitle: Main topic of this lesson'],
          practiceQuestions: [],
          estimatedMinutes: 25,
        );
        final practiceQuestions = <PracticeQuestion>[];

        final enrichedLesson = lesson.copyWith(practiceQuestions: practiceQuestions);
        lessons.add(enrichedLesson);
        previousLessons.add(lessonTitle);

        // Add small delay to avoid overwhelming the AI service
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // Fallback lesson if AI generation fails
        lessons.add(Lesson(
          id: lessonId,
          title: lessonTitle,
          description: 'Learn about $lessonTitle',
          content: 'This lesson covers the important concepts of $lessonTitle. You will learn practical skills and knowledge that you can apply in your daily life.',
          learningObjectives: ['Understand $lessonTitle', 'Apply knowledge practically'],
          keyTerms: ['$lessonTitle: Main topic of this lesson'],
          practiceQuestions: [],
          estimatedMinutes: 25,
        ));
      }
    }

    return lessons;
  }

  // Get course statistics
  Map<String, dynamic> getCourseStats(String courseId) {
    final course = _courses.firstWhere((c) => c.id == courseId);
    
    return {
      'totalLessons': course.getTotalLessonsCount(),
      'completedLessons': course.getCompletedLessonsCount(),
      'progressPercentage': course.getProgressPercentage(),
      'estimatedTotalMinutes': course.getEstimatedTotalMinutes(),
      'remainingMinutes': course.getRemainingMinutes(),
      'isCompleted': course.isCompleted(),
      'nextLesson': course.getNextLesson()?.title,
    };
  }
}
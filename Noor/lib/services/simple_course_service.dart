import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flash_card.dart';
import 'gemma_native_service.dart';

class SimpleCourseService {
  final GemmaNativeService _gemmaService = GemmaNativeService.instance;
  static const String _coursesKey = 'simple_courses';
  
  // Available subjects
  static const List<String> subjects = [
    'Mathematics',
    'Science', 
    'English',
    'Hygiene & Care',
  ];

  /// Get all available subjects with their completion status
  Future<List<Map<String, dynamic>>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString(_coursesKey);
    final completedCourses = <String, bool>{};
    
    if (coursesJson != null) {
      final coursesList = jsonDecode(coursesJson) as List;
      for (final courseData in coursesList) {
        final course = SimpleCourse.fromJson(courseData);
        completedCourses[course.id] = course.isCompleted;
      }
    }

    return subjects.map((subject) {
      final hasCompletedAny = completedCourses.entries
          .where((entry) => entry.key.startsWith(subject.toLowerCase()))
          .any((entry) => entry.value);
      
      return {
        'name': subject,
        'icon': _getSubjectIcon(subject),
        'description': _getSubjectDescription(subject),
        'hasCompletedCourses': hasCompletedAny,
      };
    }).toList();
  }

  /// Generate a new course for a subject and difficulty
  Future<SimpleCourse> generateCourse({
    required String subject,
    required DifficultyLevel difficulty,
  }) async {
    try {
      // Initialize Gemma service
      await _gemmaService.initializeModel();
      
      // Generate AI-powered flashcards with timeout
      final flashCards = await _generateAIFlashCards(subject, difficulty, 8)
          .timeout(const Duration(seconds: 45)); // Max 45 seconds total
      
      return SimpleCourse(
        id: '${subject.toLowerCase()}_${difficulty.name}_${DateTime.now().millisecondsSinceEpoch}',
        name: '$subject (${difficulty.displayName})',
        description: 'AI-enhanced course for $subject at ${difficulty.displayName} level',
        icon: _getSubjectIcon(subject),
        difficulty: difficulty,
        flashCards: flashCards,
      );
    } catch (e) {
      print('Error generating AI course, using fallback: $e');
      
      // Fallback to educational content if AI generation fails
      return _generateEducationalCourse(subject, difficulty);
    }
  }

  /// Generate AI-powered flashcards using Gemma
  Future<List<FlashCard>> _generateAIFlashCards(String subject, DifficultyLevel difficulty, int cardCount) async {
    final flashCards = <FlashCard>[];
    
    // Try to generate first 3 cards with AI, then use fallback for speed
    final aiCardCount = 3; // Reduce AI generation to speed up
    
    for (int i = 1; i <= cardCount; i++) {
      try {
        if (i <= aiCardCount) {
          // Generate with AI for first few cards
          final prompt = _buildFlashCardPrompt(subject, difficulty, i, cardCount);
          
          // Add timeout to prevent hanging
          final response = await _gemmaService.generateText(prompt, maxTokens: 300)
              .timeout(const Duration(seconds: 10));
          
          final flashCard = _parseFlashCardResponse(response, i.toString(), subject);
          if (flashCard != null) {
            flashCards.add(flashCard);
          } else {
            // Add educational fallback card if parsing fails
            flashCards.add(_createEducationalFlashCard(subject, i));
          }
          
          // Shorter delay for faster generation
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          // Use educational content for remaining cards for speed
          flashCards.add(_createEducationalFlashCard(subject, i));
        }
      } catch (e) {
        print('Error generating flashcard $i: $e');
        flashCards.add(_createEducationalFlashCard(subject, i));
      }
    }
    
    return flashCards;
  }

  String _buildFlashCardPrompt(String subject, DifficultyLevel difficulty, int cardNumber, int totalCards) {
    final difficultyText = difficulty == DifficultyLevel.beginner ? 'basic' : 
                          difficulty == DifficultyLevel.intermediate ? 'intermediate' : 'advanced';
    
    return '''Create a ${difficultyText} level educational flashcard for ${subject}. This is card ${cardNumber} of ${totalCards}.

Format your response EXACTLY like this:
TITLE: [Short topic title]
CONTENT: [2-3 sentences explaining the concept clearly and simply]
QUESTION: [A clear multiple choice question about the content]
A) [First option]
B) [Second option] 
C) [Third option]
D) [Fourth option]
CORRECT: [A, B, C, or D]
EXPLANATION: [Why the correct answer is right and others are wrong]

Make it educational, age-appropriate, and focused on practical knowledge for ${subject}.''';
  }

  FlashCard? _parseFlashCardResponse(String response, String id, String subject) {
    try {
      final lines = response.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      String title = '';
      String content = '';
      String question = '';
      List<String> options = [];
      int correctIndex = 0;
      String explanation = '';
      
      for (final line in lines) {
        final trimmed = line.trim();
        
        if (trimmed.startsWith('TITLE:')) {
          title = trimmed.substring(6).trim();
        } else if (trimmed.startsWith('CONTENT:')) {
          content = trimmed.substring(8).trim();
        } else if (trimmed.startsWith('QUESTION:')) {
          question = trimmed.substring(9).trim();
        } else if (trimmed.startsWith('A)')) {
          options.add(trimmed.substring(2).trim());
        } else if (trimmed.startsWith('B)')) {
          options.add(trimmed.substring(2).trim());
        } else if (trimmed.startsWith('C)')) {
          options.add(trimmed.substring(2).trim());
        } else if (trimmed.startsWith('D)')) {
          options.add(trimmed.substring(2).trim());
        } else if (trimmed.startsWith('CORRECT:')) {
          final correctLetter = trimmed.substring(8).trim().toUpperCase();
          correctIndex = correctLetter == 'A' ? 0 : 
                        correctLetter == 'B' ? 1 : 
                        correctLetter == 'C' ? 2 : 3;
        } else if (trimmed.startsWith('EXPLANATION:')) {
          explanation = trimmed.substring(12).trim();
        }
      }
      
      // Validate required fields
      if (title.isNotEmpty && content.isNotEmpty && question.isNotEmpty && 
          options.length >= 4 && explanation.isNotEmpty) {
        return FlashCard(
          id: id,
          title: title,
          content: content,
          question: question,
          options: options.take(4).toList(),
          correctAnswerIndex: correctIndex,
          explanation: explanation,
        );
      }
    } catch (e) {
      print('Error parsing flashcard response: $e');
    }
    
    return null;
  }

  /// Generate educational course with curated content
  SimpleCourse _generateEducationalCourse(String subject, DifficultyLevel difficulty) {
    final topics = _getSubjectTopics(subject);
    final flashCards = <FlashCard>[];
    
    for (int i = 1; i <= 8; i++) {
      final topic = topics[(i - 1) % topics.length];
      flashCards.add(FlashCard(
        id: i.toString(),
        title: topic['title'],
        content: topic['content'],
        question: topic['question'],
        options: List<String>.from(topic['options']),
        correctAnswerIndex: topic['correctIndex'],
        explanation: topic['explanation'],
      ));
    }
    
    return SimpleCourse(
      id: '${subject.toLowerCase()}_${difficulty.name}_educational',
      name: '$subject (${difficulty.displayName})',
      description: 'Educational course for $subject',
      icon: _getSubjectIcon(subject),
      difficulty: difficulty,
      flashCards: flashCards,
    );
  }

  FlashCard _createEducationalFlashCard(String subject, int cardNumber) {
    final topics = _getSubjectTopics(subject);
    final topic = topics[(cardNumber - 1) % topics.length];
    
    return FlashCard(
      id: cardNumber.toString(),
      title: topic['title'],
      content: topic['content'],
      question: topic['question'],
      options: List<String>.from(topic['options']),
      correctAnswerIndex: topic['correctIndex'],
      explanation: topic['explanation'],
    );
  }

  List<Map<String, dynamic>> _getSubjectTopics(String subject) {
    switch (subject) {
      case 'Mathematics':
        return [
          {
            'title': 'Basic Addition',
            'content': 'Addition is combining two or more numbers to get their total. When you add numbers, you are finding how many you have altogether.',
            'question': 'What is 5 + 3?',
            'options': ['6', '7', '8', '9'],
            'correctIndex': 2,
            'explanation': '5 + 3 = 8. When you add 5 and 3, you get 8 total.',
          },
          {
            'title': 'Basic Subtraction',
            'content': 'Subtraction is taking away one number from another. It helps us find the difference between numbers.',
            'question': 'What is 10 - 4?',
            'options': ['5', '6', '7', '8'],
            'correctIndex': 1,
            'explanation': '10 - 4 = 6. When you take away 4 from 10, you have 6 left.',
          },
          {
            'title': 'Multiplication Basics',
            'content': 'Multiplication is repeated addition. It helps us find the total when we have equal groups.',
            'question': 'What is 3 × 4?',
            'options': ['10', '11', '12', '13'],
            'correctIndex': 2,
            'explanation': '3 × 4 = 12. This is the same as adding 3 four times: 3 + 3 + 3 + 3 = 12.',
          },
          {
            'title': 'Division Basics',
            'content': 'Division is splitting a number into equal groups. It helps us share things fairly.',
            'question': 'What is 12 ÷ 3?',
            'options': ['3', '4', '5', '6'],
            'correctIndex': 1,
            'explanation': '12 ÷ 3 = 4. When you divide 12 into 3 equal groups, each group has 4.',
          },
        ];
      case 'Science':
        return [
          {
            'title': 'The Water Cycle',
            'content': 'Water moves around Earth in a cycle. It evaporates from oceans, forms clouds, and falls as rain.',
            'question': 'What happens when water evaporates?',
            'options': ['It freezes', 'It becomes gas', 'It becomes solid', 'It disappears'],
            'correctIndex': 1,
            'explanation': 'When water evaporates, it changes from liquid to gas (water vapor) and rises into the air.',
          },
          {
            'title': 'Plants Need Sunlight',
            'content': 'Plants use sunlight to make their own food through photosynthesis. This process also produces oxygen.',
            'question': 'What do plants need to make food?',
            'options': ['Only water', 'Only soil', 'Sunlight, water, and air', 'Only sunlight'],
            'correctIndex': 2,
            'explanation': 'Plants need sunlight, water, and carbon dioxide from air to make food through photosynthesis.',
          },
          {
            'title': 'States of Matter',
            'content': 'Matter exists in three main states: solid, liquid, and gas. Water can be all three states.',
            'question': 'What is water vapor?',
            'options': ['Solid water', 'Liquid water', 'Gas water', 'Frozen water'],
            'correctIndex': 2,
            'explanation': 'Water vapor is water in its gas state. You can see it as steam from hot water.',
          },
          {
            'title': 'Animal Habitats',
            'content': 'Animals live in different habitats that provide food, water, and shelter. Each habitat has unique features.',
            'question': 'What do animals need from their habitat?',
            'options': ['Only food', 'Only water', 'Food, water, and shelter', 'Only shelter'],
            'correctIndex': 2,
            'explanation': 'Animals need food for energy, water to drink, and shelter for protection from weather and predators.',
          },
        ];
      case 'English':
        return [
          {
            'title': 'Nouns',
            'content': 'A noun is a word that names a person, place, thing, or idea. Examples: cat, school, happiness.',
            'question': 'Which word is a noun?',
            'options': ['Run', 'Happy', 'Book', 'Quickly'],
            'correctIndex': 2,
            'explanation': 'Book is a noun because it names a thing. Run is a verb, happy is an adjective, and quickly is an adverb.',
          },
          {
            'title': 'Verbs',
            'content': 'A verb is an action word. It tells us what someone or something does. Examples: run, jump, think.',
            'question': 'Which word is a verb?',
            'options': ['Table', 'Beautiful', 'Dance', 'Red'],
            'correctIndex': 2,
            'explanation': 'Dance is a verb because it shows an action. Table is a noun, beautiful is an adjective, and red is an adjective.',
          },
          {
            'title': 'Adjectives',
            'content': 'An adjective describes a noun. It tells us more about how something looks, feels, or sounds.',
            'question': 'Which word is an adjective?',
            'options': ['Car', 'Sing', 'Big', 'Tomorrow'],
            'correctIndex': 2,
            'explanation': 'Big is an adjective because it describes the size of something. Car is a noun, sing is a verb, and tomorrow is an adverb.',
          },
          {
            'title': 'Sentences',
            'content': 'A sentence is a group of words that expresses a complete thought. It starts with a capital letter and ends with punctuation.',
            'question': 'What makes a complete sentence?',
            'options': ['Just a noun', 'Just a verb', 'A complete thought', 'Just adjectives'],
            'correctIndex': 2,
            'explanation': 'A complete sentence must express a complete thought and usually has a subject and a verb.',
          },
        ];
      case 'Hygiene & Care':
        return [
          {
            'title': 'Hand Washing',
            'content': 'Washing hands with soap and water removes germs and prevents illness. Wash for at least 20 seconds.',
            'question': 'How long should you wash your hands?',
            'options': ['5 seconds', '10 seconds', '20 seconds', '1 minute'],
            'correctIndex': 2,
            'explanation': '20 seconds is the recommended time to wash hands properly and remove germs effectively.',
          },
          {
            'title': 'Brushing Teeth',
            'content': 'Brush your teeth twice a day to remove food and bacteria. This prevents cavities and keeps teeth healthy.',
            'question': 'How often should you brush your teeth?',
            'options': ['Once a week', 'Once a day', 'Twice a day', 'Three times a day'],
            'correctIndex': 2,
            'explanation': 'Brushing twice a day (morning and night) is recommended to maintain good oral health.',
          },
          {
            'title': 'Healthy Eating',
            'content': 'Eating fruits and vegetables gives your body vitamins and nutrients. They help you grow strong and healthy.',
            'question': 'Why are fruits and vegetables important?',
            'options': ['They taste good', 'They provide vitamins', 'They are colorful', 'They are cheap'],
            'correctIndex': 1,
            'explanation': 'Fruits and vegetables provide essential vitamins and nutrients that help your body stay healthy and strong.',
          },
          {
            'title': 'Getting Enough Sleep',
            'content': 'Sleep helps your body rest and grow. Children need 8-10 hours of sleep each night to stay healthy.',
            'question': 'How much sleep do children need?',
            'options': ['4-5 hours', '6-7 hours', '8-10 hours', '12-14 hours'],
            'correctIndex': 2,
            'explanation': 'Children need 8-10 hours of sleep each night for proper growth, learning, and health.',
          },
        ];
      default:
        return [
          {
            'title': 'Learning Basics',
            'content': 'Learning is the process of gaining new knowledge and skills. Practice and repetition help us learn better.',
            'question': 'What helps us learn better?',
            'options': ['Sleeping all day', 'Practice and repetition', 'Watching TV', 'Playing games only'],
            'correctIndex': 1,
            'explanation': 'Practice and repetition help strengthen our memory and understanding of new concepts.',
          },
        ];
    }
  }

  /// Save course progress
  Future<void> saveCourse(SimpleCourse course) async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString(_coursesKey);
    List<Map<String, dynamic>> courses = [];
    
    if (coursesJson != null) {
      courses = List<Map<String, dynamic>>.from(jsonDecode(coursesJson));
    }
    
    // Remove existing course with same ID
    courses.removeWhere((c) => c['id'] == course.id);
    
    // Add updated course
    courses.add(course.toJson());
    
    await prefs.setString(_coursesKey, jsonEncode(courses));
  }

  /// Get saved course by ID
  Future<SimpleCourse?> getCourse(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString(_coursesKey);
    
    if (coursesJson != null) {
      final courses = List<Map<String, dynamic>>.from(jsonDecode(coursesJson));
      final courseData = courses.firstWhere(
        (c) => c['id'] == courseId,
        orElse: () => <String, dynamic>{},
      );
      
      if (courseData.isNotEmpty) {
        return SimpleCourse.fromJson(courseData);
      }
    }
    
    return null;
  }

  /// Get all courses for a subject
  Future<List<SimpleCourse>> getCoursesForSubject(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString(_coursesKey);
    
    if (coursesJson != null) {
      final courses = List<Map<String, dynamic>>.from(jsonDecode(coursesJson));
      return courses
          .where((c) => c['id'].toString().startsWith(subject.toLowerCase()))
          .map((c) => SimpleCourse.fromJson(c))
          .toList();
    }
    
    return [];
  }

  /// Update course progress
  Future<void> updateCourseProgress(String courseId, int currentCardIndex, bool isCompleted) async {
    final course = await getCourse(courseId);
    if (course != null) {
      final updatedCourse = course.copyWith(
        currentCardIndex: currentCardIndex,
        isCompleted: isCompleted,
      );
      await saveCourse(updatedCourse);
    }
  }

  /// Delete a course
  Future<void> deleteCourse(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString(_coursesKey);
    
    if (coursesJson != null) {
      final courses = List<Map<String, dynamic>>.from(jsonDecode(coursesJson));
      courses.removeWhere((c) => c['id'] == courseId);
      await prefs.setString(_coursesKey, jsonEncode(courses));
    }
  }

  /// Get completion statistics
  Future<Map<String, dynamic>> getCompletionStats() async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString(_coursesKey);
    
    int totalCourses = 0;
    int completedCourses = 0;
    Map<String, int> subjectStats = {};
    
    if (coursesJson != null) {
      final courses = List<Map<String, dynamic>>.from(jsonDecode(coursesJson));
      totalCourses = courses.length;
      
      for (final courseData in courses) {
        final course = SimpleCourse.fromJson(courseData);
        if (course.isCompleted) {
          completedCourses++;
        }
        
        // Extract subject from course name
        final subject = course.name.split(' (')[0];
        subjectStats[subject] = (subjectStats[subject] ?? 0) + 1;
      }
    }
    
    return {
      'totalCourses': totalCourses,
      'completedCourses': completedCourses,
      'completionRate': totalCourses > 0 ? completedCourses / totalCourses : 0.0,
      'subjectStats': subjectStats,
    };
  }

  String _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Mathematics':
        return '🔢';
      case 'Science':
        return '🔬';
      case 'English':
        return '📚';
      case 'Hygiene & Care':
        return '🏥';
      default:
        return '📖';
    }
  }

  String _getSubjectDescription(String subject) {
    switch (subject) {
      case 'Mathematics':
        return 'Learn essential math skills for daily life and problem solving';
      case 'Science':
        return 'Discover scientific principles that help you understand the world';
      case 'English':
        return 'Improve your English communication skills for better opportunities';
      case 'Hygiene & Care':
        return 'Essential health and hygiene knowledge for you and your family';
      default:
        return 'Learn important concepts in $subject';
    }
  }
}
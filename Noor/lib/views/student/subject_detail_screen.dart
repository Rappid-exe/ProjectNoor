import 'package:flutter/material.dart';
import '../../models/flash_card.dart';
import '../../services/simple_course_service.dart';
import 'flash_card_course_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subject;

  const SubjectDetailScreen({
    Key? key,
    required this.subject,
  }) : super(key: key);

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final SimpleCourseService _courseService = SimpleCourseService();
  List<SimpleCourse> _existingCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingCourses();
  }

  Future<void> _loadExistingCourses() async {
    try {
      final courses = await _courseService.getCoursesForSubject(widget.subject);
      setState(() {
        _existingCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getSubjectColor().withValues(alpha: 0.8),
                    _getSubjectColor(),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.subject,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            _getSubjectIcon(),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getSubjectDescription(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choose Your Level',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select the difficulty level that matches your current knowledge',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Difficulty levels
                          Expanded(
                            child: ListView(
                              children: DifficultyLevel.values.map((difficulty) {
                                final existingCourse = _existingCourses
                                    .where((c) => c.difficulty == difficulty)
                                    .toList();
                                
                                return _buildDifficultyCard(difficulty, existingCourse);
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(DifficultyLevel difficulty, List<SimpleCourse> existingCourses) {
    final hasCompletedCourse = existingCourses.any((c) => c.isCompleted);
    final hasInProgressCourse = existingCourses.any((c) => !c.isCompleted && c.currentCardIndex > 0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _startCourse(difficulty),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: hasCompletedCourse
                  ? Border.all(color: Colors.green, width: 2)
                  : hasInProgressCourse
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
            ),
            child: Row(
              children: [
                // Difficulty icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(difficulty).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          _getDifficultyIcon(difficulty),
                          color: _getDifficultyColor(difficulty),
                          size: 28,
                        ),
                      ),
                      if (hasCompletedCourse)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Difficulty info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        difficulty.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        difficulty.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Status indicator
                      if (hasCompletedCourse)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Completed ✓',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        )
                      else if (hasInProgressCourse)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'In Progress',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Start New Course',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startCourse(DifficultyLevel difficulty) async {
    // Check if there's an existing course
    final existingCourse = _existingCourses
        .where((c) => c.difficulty == difficulty)
        .toList();

    if (existingCourse.isNotEmpty && !existingCourse.first.isCompleted) {
      // Continue existing course
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlashCardCourseScreen(course: existingCourse.first),
        ),
      ).then((_) => _loadExistingCourses());
    } else {
      // Generate new course
      _showGeneratingDialog();
      
      try {
        final course = await _courseService.generateCourse(
          subject: widget.subject,
          difficulty: difficulty,
        );
        
        Navigator.pop(context); // Close loading dialog
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCardCourseScreen(course: course),
          ),
        ).then((_) => _loadExistingCourses());
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGeneratingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getSubjectColor().withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    color: _getSubjectColor(),
                    strokeWidth: 3,
                  ),
                  Text(
                    _getSubjectIcon(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '🤖 Creating Your Course',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getSubjectColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Our AI is generating personalized flash cards with emojis and practical examples just for you! ✨',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This usually takes 10-30 seconds',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor() {
    switch (widget.subject) {
      case 'Mathematics':
        return Colors.blue;
      case 'Science':
        return Colors.green;
      case 'English':
        return Colors.purple;
      case 'Hygiene & Care':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getSubjectIcon() {
    switch (widget.subject) {
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

  String _getSubjectDescription() {
    switch (widget.subject) {
      case 'Mathematics':
        return 'Learn essential math skills through interactive flash cards with practical examples from daily life';
      case 'Science':
        return 'Discover scientific principles that help you understand the world around you';
      case 'English':
        return 'Improve your English communication skills for better opportunities and connections';
      case 'Hygiene & Care':
        return 'Essential health and hygiene knowledge to keep you and your family healthy and safe';
      default:
        return 'Learn important concepts in ${widget.subject}';
    }
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }

  IconData _getDifficultyIcon(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Icons.school;
      case DifficultyLevel.intermediate:
        return Icons.trending_up;
      case DifficultyLevel.advanced:
        return Icons.emoji_events;
    }
  }
}
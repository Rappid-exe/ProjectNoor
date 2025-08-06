import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/flash_card.dart';
import '../../services/simple_course_service.dart';

class FlashCardCourseScreen extends StatefulWidget {
  final SimpleCourse course;

  const FlashCardCourseScreen({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  State<FlashCardCourseScreen> createState() => _FlashCardCourseScreenState();
}

class _FlashCardCourseScreenState extends State<FlashCardCourseScreen> {
  final SimpleCourseService _courseService = SimpleCourseService();
  late SimpleCourse _course;
  bool _showFinalQuiz = false;
  FlashCard? _quizCard;
  int? _selectedAnswerIndex;
  bool _showExplanation = false;
  bool _isAnswerCorrect = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }

  FlashCard get _currentCard => _course.flashCards[_course.currentCardIndex];
  bool get _isLastCard => _course.currentCardIndex >= _course.flashCards.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => _showExitDialog(),
                      ),
                      Expanded(
                        child: Text(
                          _course.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${_course.currentCardIndex + 1}/${_course.flashCards.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_course.currentCardIndex + 1) / _course.flashCards.length,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            // Flash Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Flash Card
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                _getSubjectColor().withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: _showFinalQuiz ? _buildQuestionView() : _buildContentView(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    if (!_showFinalQuiz)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(_isLastCard ? Icons.quiz : Icons.arrow_forward),
                          label: Text(_isLastCard ? 'Take Final Quiz' : 'Next Card'),
                          onPressed: _isLastCard ? _startFinalQuiz : _nextCard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getSubjectColor(),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else if (_showExplanation)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.celebration),
                          label: const Text('Complete Course!'),
                          onPressed: _completeCourse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAnswerCorrect ? Colors.green : _getSubjectColor(),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else if (_selectedAnswerIndex != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Submit Answer'),
                          onPressed: _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getSubjectColor(),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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

  Widget _buildContentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card title
        Text(
          _currentCard.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _getSubjectColor(),
          ),
        ),
        const SizedBox(height: 24),

        // Card content
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              _currentCard.content,
              style: const TextStyle(
                fontSize: 18,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ),

        // Study tip
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getSubjectColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getSubjectColor().withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: _getSubjectColor()),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Take your time to understand this concept before testing yourself!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getSubjectColor(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionView() {
    final card = _quizCard!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quiz header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getSubjectColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getSubjectColor().withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.quiz, color: _getSubjectColor()),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Final Quiz - Test your understanding!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getSubjectColor(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Question
        Text(
          card.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // Answer options
        Expanded(
          child: ListView.builder(
            itemCount: card.options.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedAnswerIndex == index;
              final isCorrect = index == card.correctAnswerIndex;
              final showResult = _showExplanation;

              Color? backgroundColor;
              Color? borderColor;
              Color? textColor;

              if (showResult) {
                if (isCorrect) {
                  backgroundColor = Colors.green.shade50;
                  borderColor = Colors.green.shade300;
                  textColor = Colors.green.shade800;
                } else if (isSelected && !isCorrect) {
                  backgroundColor = Colors.red.shade50;
                  borderColor = Colors.red.shade300;
                  textColor = Colors.red.shade800;
                }
              } else if (isSelected) {
                backgroundColor = _getSubjectColor().withOpacity(0.1);
                borderColor = _getSubjectColor();
                textColor = _getSubjectColor();
              }

              return GestureDetector(
                onTap: _showExplanation ? null : () => _selectAnswer(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor ?? Colors.grey.shade300,
                      width: isSelected || (showResult && isCorrect) ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: textColor ?? Colors.grey.shade600,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          card.options[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor ?? Colors.black87,
                            fontWeight: isSelected || (showResult && isCorrect) 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (showResult && isCorrect)
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                      if (showResult && isSelected && !isCorrect)
                        Icon(Icons.cancel, color: Colors.red.shade600),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Explanation
        if (_showExplanation) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAnswerCorrect ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isAnswerCorrect ? Colors.green.shade200 : Colors.blue.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isAnswerCorrect ? Icons.check_circle : Icons.lightbulb,
                      color: _isAnswerCorrect ? Colors.green.shade600 : Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isAnswerCorrect ? 'Excellent! 🎉' : 'Good try! 💪',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isAnswerCorrect ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.explanation,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isAnswerCorrect ? Colors.green.shade700 : Colors.blue.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswerIndex = index;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswerIndex == null) return;

    final isCorrect = _selectedAnswerIndex == _currentCard.correctAnswerIndex;
    
    setState(() {
      _isAnswerCorrect = isCorrect;
      _showExplanation = true;
    });
  }

  void _startFinalQuiz() {
    // Select a random card for the final quiz
    final random = Random();
    final availableCards = List<FlashCard>.from(_course.flashCards);
    availableCards.shuffle(random);
    
    setState(() {
      _quizCard = availableCards.first;
      _showFinalQuiz = true;
      _selectedAnswerIndex = null;
      _showExplanation = false;
      _isAnswerCorrect = false;
    });
  }

  Future<void> _nextCard() async {
    // Move to next card
    final updatedCourse = _course.copyWith(
      currentCardIndex: _course.currentCardIndex + 1,
    );
    
    await _courseService.saveCourse(updatedCourse);
    
    setState(() {
      _course = updatedCourse;
    });
  }

  Future<void> _completeCourse() async {
    // Complete the course
    final completedCourse = _course.copyWith(
      currentCardIndex: _course.flashCards.length,
      isCompleted: true,
    );
    
    await _courseService.saveCourse(completedCourse);
    
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final percentage = _isAnswerCorrect ? 100 : 0;
    final passed = _isAnswerCorrect;
    
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
                color: (passed ? Colors.green : Colors.orange).shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                passed ? Icons.celebration : Icons.psychology,
                color: passed ? Colors.green.shade600 : Colors.orange.shade600,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              passed ? 'Excellent Work! 🎉' : 'Course Complete! 💪',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: passed ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have successfully completed the ${_course.name} course!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            if (_showFinalQuiz) ...[
              const SizedBox(height: 16),
              Text(
                'Quiz Score: ${passed ? "Correct" : "Incorrect"}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: passed ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to subject screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: passed ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Continue Learning'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Course?'),
        content: const Text('Your progress will be saved. You can continue later from where you left off.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Save current progress
              await _courseService.saveCourse(_course);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit course
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor() {
    final subject = _course.name.split(' (')[0];
    switch (subject) {
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
}
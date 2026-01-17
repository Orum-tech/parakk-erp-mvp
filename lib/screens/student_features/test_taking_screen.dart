import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/test_model.dart';
import '../../services/test_service.dart';

class TestTakingScreen extends StatefulWidget {
  final TestModel test;

  const TestTakingScreen({super.key, required this.test});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  final TestService _testService = TestService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentQuestionIndex = 0;
  final Map<int, int?> _selectedAnswers = {};
  bool _isSubmitted = false;
  final bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final question = widget.test.questions[_currentQuestionIndex];
    final totalQuestions = widget.test.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(widget.test.title),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${((_currentQuestionIndex + 1) / totalQuestions * 100).toInt()}%',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / totalQuestions,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                ),
              ],
            ),
          ),
          // Question Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...question.options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final isSelected = _selectedAnswers[_currentQuestionIndex] == index;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAnswers[_currentQuestionIndex] = index;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1565C0).withOpacity(0.1)
                                      : Colors.grey[50],
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF1565C0)
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? const Color(0xFF1565C0)
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentQuestionIndex < totalQuestions - 1) {
                        setState(() {
                          _currentQuestionIndex++;
                        });
                      } else {
                        _showSubmitDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentQuestionIndex < totalQuestions - 1
                                ? 'Next'
                                : 'Submit Test',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog() {
    final answeredCount = _selectedAnswers.values.where((a) => a != null).length;
    final totalQuestions = widget.test.questions.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Text(
          'You have answered $answeredCount out of $totalQuestions questions.\n\nDo you want to submit the test?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitTest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitTest() {
    // Calculate score
    int totalScore = 0;
    for (int i = 0; i < widget.test.questions.length; i++) {
      final selectedIndex = _selectedAnswers[i];
      if (selectedIndex != null &&
          selectedIndex == widget.test.questions[i].correctAnswerIndex) {
        totalScore += widget.test.questions[i].marks;
      }
    }

    final percentage = (totalScore / widget.test.totalMarks * 100).toInt();

    setState(() {
      _isSubmitted = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test Submitted!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Score: $totalScore / ${widget.test.totalMarks}'),
            const SizedBox(height: 8),
            Text('Percentage: $percentage%'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to tests list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

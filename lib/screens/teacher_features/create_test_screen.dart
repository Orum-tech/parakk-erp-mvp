import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/test_service.dart';
import '../../services/marks_service.dart';
import '../../models/test_model.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final TestService _testService = TestService();
  final MarksService _marksService = MarksService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _chapterController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String? _selectedSubject;
  TestType _selectedTestType = TestType.quiz;
  final List<String> _selectedClasses = [];
  List<Map<String, String>> _availableSubjects = [];
  List<Map<String, String>> _availableClasses = [];
  final List<TestQuestion> _questions = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _targetAllClasses = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _chapterController.dispose();
    _topicController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final subjects = await _marksService.getTeacherSubjects(user.uid);
      final classes = await _marksService.getTeacherClasses(user.uid);

      setState(() {
        _availableSubjects = subjects;
        _availableClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addQuestion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddQuestionScreen()),
    );

    if (result != null && result is TestQuestion) {
      setState(() {
        _questions.add(result);
      });
    }
  }

  void _editQuestion(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuestionScreen(question: _questions[index]),
      ),
    );

    if (result != null && result is TestQuestion) {
      setState(() {
        _questions[index] = result;
      });
    }
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveTest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_targetAllClasses && _selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one class or select "All Classes"'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final duration = int.tryParse(_durationController.text) ?? 30;
      if (duration <= 0) {
        throw Exception('Please enter a valid duration in minutes');
      }

      final targetAudience = _targetAllClasses 
          ? ['all'] 
          : _selectedClasses.map((c) => c).toList();

      await _testService.createOrUpdateTest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        subject: _selectedSubject!,
        chapter: _chapterController.text.trim().isEmpty 
            ? null 
            : _chapterController.text.trim(),
        topic: _topicController.text.trim().isEmpty 
            ? null 
            : _topicController.text.trim(),
        testType: _selectedTestType,
        questions: _questions,
        duration: duration,
        startDate: _startDate!,
        endDate: _endDate,
        targetAudience: targetAudience,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Create Test", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Create Test", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Test Title *',
              hint: 'Enter test title',
              icon: Icons.title,
              validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description *',
              hint: 'Enter test description',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              label: 'Subject *',
              value: _selectedSubject,
              items: _availableSubjects.map((s) => s['name']!).toList(),
              onChanged: (value) => setState(() => _selectedSubject = value),
            ),
            const SizedBox(height: 15),
            _buildTestTypeDropdown(),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _chapterController,
              label: 'Chapter (Optional)',
              hint: 'Enter chapter name',
              icon: Icons.menu_book,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _topicController,
              label: 'Topic (Optional)',
              hint: 'Enter topic name',
              icon: Icons.topic,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _durationController,
              label: 'Duration (minutes) *',
              hint: 'Enter duration in minutes',
              icon: Icons.timer,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Duration is required';
                final duration = int.tryParse(value!);
                if (duration == null || duration <= 0) return 'Enter a valid duration';
                return null;
              },
            ),
            const SizedBox(height: 15),
            _buildDateField('Start Date *', _startDate, true),
            const SizedBox(height: 15),
            _buildDateField('End Date (Optional)', _endDate, false),
            const SizedBox(height: 20),
            _buildTargetAudienceSection(),
            const SizedBox(height: 20),
            _buildQuestionsSection(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Create Test',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.subject),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTestTypeDropdown() {
    return DropdownButtonFormField<TestType>(
      initialValue: _selectedTestType,
      decoration: InputDecoration(
        labelText: 'Test Type *',
        prefixIcon: const Icon(Icons.quiz),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: TestType.values.map((type) {
        final name = type.toString().split('.').last;
        return DropdownMenuItem(
          value: type,
          child: Text(name[0].toUpperCase() + name.substring(1)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedTestType = value!),
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isRequired) {
    return InkWell(
      onTap: () => _selectDate(isRequired),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetAudienceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Audience',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            title: const Text('All Classes'),
            value: _targetAllClasses,
            onChanged: (value) {
              setState(() {
                _targetAllClasses = value ?? true;
                if (_targetAllClasses) {
                  _selectedClasses.clear();
                }
              });
            },
          ),
          if (!_targetAllClasses) ...[
            const SizedBox(height: 10),
            ..._availableClasses.map((classData) {
              final classId = classData['id']!;
              final className = classData['name']!;
              return CheckboxListTile(
                title: Text(className),
                value: _selectedClasses.contains(classId),
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedClasses.add(classId);
                    } else {
                      _selectedClasses.remove(classId);
                    }
                  });
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Questions (${_questions.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
            ],
          ),
          if (_questions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'No questions added yet. Click "Add Question" to get started.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...List.generate(_questions.length, (index) {
              final question = _questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    question.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${question.options.length} options • ${question.marks} marks'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editQuestion(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteQuestion(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// Add Question Screen
class AddQuestionScreen extends StatefulWidget {
  final TestQuestion? question;

  const AddQuestionScreen({super.key, this.question});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _marksController = TextEditingController();
  final TextEditingController _explanationController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctAnswerIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionController.text = widget.question!.question;
      _marksController.text = widget.question!.marks.toString();
      _explanationController.text = widget.question!.explanation ?? '';
      _optionControllers.clear();
      for (var option in widget.question!.options) {
        _optionControllers.add(TextEditingController(text: option));
      }
      _correctAnswerIndex = widget.question!.correctAnswerIndex;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _marksController.dispose();
    _explanationController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        if (_correctAnswerIndex >= _optionControllers.length) {
          _correctAnswerIndex = _optionControllers.length - 1;
        }
      });
    }
  }

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) return;
    if (_optionControllers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 options'), backgroundColor: Colors.red),
      );
      return;
    }

    final options = _optionControllers.map((c) => c.text.trim()).where((o) => o.isNotEmpty).toList();
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All options must be filled'), backgroundColor: Colors.red),
      );
      return;
    }

    final question = TestQuestion(
      question: _questionController.text.trim(),
      options: options,
      correctAnswerIndex: _correctAnswerIndex,
      marks: int.tryParse(_marksController.text) ?? 1,
      explanation: _explanationController.text.trim().isEmpty 
          ? null 
          : _explanationController.text.trim(),
    );

    Navigator.pop(context, question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question *',
                hintText: 'Enter the question',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Question is required' : null,
            ),
            const SizedBox(height: 20),
            const Text('Options *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctAnswerIndex,
                      onChanged: (value) => setState(() => _correctAnswerIndex = value!),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          filled: true,
                          fillColor: Colors.white,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          suffixIcon: _optionControllers.length > 2
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeOption(index),
                                )
                              : null,
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Option is required' : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _marksController,
              decoration: const InputDecoration(
                labelText: 'Marks',
                hintText: 'Enter marks for this question',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Marks is required';
                final marks = int.tryParse(value!);
                if (marks == null || marks <= 0) return 'Enter valid marks';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _explanationController,
              decoration: const InputDecoration(
                labelText: 'Explanation (Optional)',
                hintText: 'Enter explanation for the correct answer',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Save Question',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_data.dart';
import 'quiz_result_screen.dart';
import '../services/quiz_manager.dart';
import '../services/quiz_repository.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.onBackPressed});

  final VoidCallback? onBackPressed;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizManager? _manager;
  String? _error;
  bool _isLoading = true;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final data = await const QuizRepository().loadQuiz();
      if (!mounted) return;
      final manager = QuizManager(data: data, preferences: preferences);
      if (!mounted) return;
      setState(() => _manager = manager);
      await manager.startRandomQuiz();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startRandomQuiz() async {
    final manager = _manager;
    if (manager == null) return;
    setState(() => _isLoading = true);
    await manager.startRandomQuiz();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _showResult = false;
    });
  }

  void _handleBackPressed() {
    _manager?.resetSession();
    widget.onBackPressed?.call();
  }

  Future<void> _restartQuiz() async {
    _manager?.resetSession();
    await _startRandomQuiz();
  }

  Future<void> _selectAnswer(int answerIndex) async {
    final manager = _manager;
    if (manager == null) return;
    await manager.selectAnswer(answerIndex);
    if (mounted) setState(() {});
  }

  Future<void> _nextQuestion() async {
    final manager = _manager;
    if (manager == null) return;
    final finished = await manager.nextQuestion();
    if (!mounted) return;
    setState(() {
      _showResult = finished;
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = _manager;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          _showResult
              ? null
              : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  onPressed: _handleBackPressed,
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF176B87)),
                  tooltip: 'Back to home',
                ),
                title:
                    _showResult || manager == null
                        ? const Text(
                          'Quiz Result',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF123B5D),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                        : _buildProgressTitle(manager),
                actions: [
                  if (manager != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFF4B400),
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${manager.score}',
                            style: const TextStyle(
                              color: Color(0xFF123B5D),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      body: _buildBody(manager),
    );
  }

  Widget _buildProgressTitle(QuizManager manager) {
    final total = manager.sessionQuestions.length;
    final progress = total == 0 ? 0.0 : (manager.currentIndex + 1) / total;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Question ${manager.currentIndex + 1} of $total',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF123B5D),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: const Color(0xFFDCECF4),
              color: const Color(0xFF176B87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(QuizManager? manager) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF176B87)),
      );
    }
    if (_error != null || manager == null) {
      return Center(
        child: Text(
          'Unable to load quiz data.',
          style: const TextStyle(color: Color(0xFF35627F)),
        ),
      );
    }
    if (_showResult) {
      return QuizResultScreen(
        score: manager.score,
        totalQuestions: manager.sessionQuestions.length,
        onRestart: _restartQuiz,
      );
    }
    if (manager.hasSession) return _buildQuestion(manager);
    return Center(
      child: FilledButton(
        onPressed: _startRandomQuiz,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF176B87)),
        child: const Text('Start Quiz'),
      ),
    );
  }

  Widget _buildQuestion(QuizManager manager) {
    final question = manager.currentQuestion!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 24),
      children: [
        Text(
          question.question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: Color(0xFF123B5D),
          ),
        ),
        const SizedBox(height: 30),
        if (question.type == 'image_choice')
          _buildImageChoices(question)
        else
          _buildTextChoices(question),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: manager.selectedAnswerIndex == null ? null : _nextQuestion,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF176B87),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFDCECF4),
            disabledForegroundColor: const Color(0xFF6D8795),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(manager.isLastQuestion ? 'Finish Quiz' : 'Next Question'),
        ),
      ],
    );
  }

  Widget _buildImageChoices(QuizQuestion question) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: question.choices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final choice = question.choices[index];
        return _ChoiceCard(
          selected: _manager?.selectedAnswerIndex == index,
          correct:
              _manager?.selectedAnswerIndex != null &&
              index == question.answerIndex,
          wrong:
              _manager?.selectedAnswerIndex == index &&
              index != question.answerIndex,
          onTap: () => _selectAnswer(index),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    QuizRepository.normalizeAssetPath(
                      choice.imagePath ?? choice.imageName,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF6D8795),
                          size: 42,
                        ),
                  ),
                ),
              ),
              Text(
                choice.label ?? String.fromCharCode(65 + index),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF176B87),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextChoices(QuizQuestion question) {
    return Column(
      children: [
        if (question.questionImagePath != null) ...[
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA9D0DF)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                QuizRepository.normalizeAssetPath(question.questionImagePath),
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF6D8795),
                      size: 42,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: question.choices.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 2.0,
          ),
          itemBuilder: (context, index) {
            return _ChoiceCard(
              selected: _manager?.selectedAnswerIndex == index,
              correct:
                  _manager?.selectedAnswerIndex != null &&
                  index == question.answerIndex,
              wrong:
                  _manager?.selectedAnswerIndex == index &&
                  index != question.answerIndex,
              onTap: () => _selectAnswer(index),
              child: Row(
                children: [
                  Text(
                    String.fromCharCode(65 + index),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      question.choices[index].displayText,
                      style: const TextStyle(
                        color: Color(0xFF173F5A),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              wrong
                  ? const Color(0xFFFFE5E5)
                  : correct
                  ? const Color(0xFFBDEEFF)
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                wrong
                    ? const Color(0xFFE04B4B)
                    : correct
                    ? const Color(0xFF0077B6)
                    : selected
                    ? const Color(0xFF176B87)
                    : const Color(0xFFA9D0DF),
            width: selected || correct || wrong ? 2 : 1,
          ),
          boxShadow:
              correct
                  ? const [
                    BoxShadow(
                      color: Color(0x6677D9FF),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: child,
      ),
    );
  }
}

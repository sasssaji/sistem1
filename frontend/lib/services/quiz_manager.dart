import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_data.dart';

class QuizManager {
  QuizManager({required this.data, required this.preferences, Random? random})
    : _random = random ?? Random();

  static const int questionsPerSession = 5;

  final QuizData data;
  final SharedPreferences preferences;
  final Random _random;
  final Map<String, Set<int>> _usedQuestionIds = {};

  List<QuizQuestion> _sessionQuestions = [];
  List<QuizCategory> _sessionCategories = [];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;

  QuizCategory? get currentCategory => _currentCategory;
  QuizCategory? _currentCategory;
  List<QuizQuestion> get sessionQuestions =>
      List.unmodifiable(_sessionQuestions);
  int get currentIndex => _currentIndex;
  int get score => _score;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get hasSession => _sessionQuestions.isNotEmpty;
  QuizQuestion? get currentQuestion =>
      hasSession ? _sessionQuestions[_currentIndex] : null;
  bool get isLastQuestion =>
      hasSession && _currentIndex == _sessionQuestions.length - 1;

  Future<void> startRandomQuiz() async {
    final available = <({QuizCategory category, QuizQuestion question})>[];
    for (final category in data.categories) {
      final used = await _loadUsedIds(category);
      var remaining =
          category.questions
              .where((question) => !used.contains(question.id))
              .map((question) => (category: category, question: question))
              .toList();
      if (remaining.isEmpty && category.questions.isNotEmpty) {
        used.clear();
        await _saveUsedIds(category);
        remaining =
            category.questions
                .map((question) => (category: category, question: question))
                .toList();
      }
      available.addAll(remaining);
    }

    if (available.isEmpty) return;
    available.shuffle(_random);

    final selected = <({QuizCategory category, QuizQuestion question})>[];
    final selectedIds = <int>{};
    for (final entry in available) {
      if (selectedIds.add(entry.question.id)) {
        selected.add(entry);
      }
      if (selected.length == questionsPerSession) break;
    }
    _sessionQuestions = selected.map((entry) => entry.question).toList();
    _sessionCategories = selected.map((entry) => entry.category).toList();
    _currentCategory = _sessionCategories.first;
    _currentIndex = 0;
    _score = 0;
    _selectedAnswerIndex = null;
    await _markCurrentQuestionDisplayed();
  }

  Future<void> selectAnswer(int answerIndex) async {
    if (_selectedAnswerIndex != null || currentQuestion == null) return;
    _selectedAnswerIndex = answerIndex;
    if (answerIndex == currentQuestion!.answerIndex) _score++;
  }

  Future<bool> nextQuestion() async {
    if (!hasSession || _selectedAnswerIndex == null) return false;
    if (isLastQuestion) return true;

    _currentIndex++;
    _currentCategory = _sessionCategories[_currentIndex];
    _selectedAnswerIndex = null;
    await _markCurrentQuestionDisplayed();
    return false;
  }

  void resetSession() {
    _sessionQuestions = [];
    _sessionCategories = [];
    _currentCategory = null;
    _currentIndex = 0;
    _score = 0;
    _selectedAnswerIndex = null;
  }

  Future<Set<int>> _loadUsedIds(QuizCategory category) async {
    final cached = _usedQuestionIds[category.id];
    if (cached != null) return cached;

    final stored = preferences.getStringList(_storageKey(category)) ?? [];
    final used = stored.map(int.tryParse).whereType<int>().toSet();
    _usedQuestionIds[category.id] = used;
    return used;
  }

  Future<void> _markCurrentQuestionDisplayed() async {
    final category = _currentCategory;
    final question = currentQuestion;
    if (category == null || question == null) return;

    final used = await _loadUsedIds(category);
    used.add(question.id);
    await _saveUsedIds(category);
  }

  Future<void> _saveUsedIds(QuizCategory category) async {
    final used = _usedQuestionIds[category.id] ?? <int>{};
    await preferences.setStringList(
      _storageKey(category),
      used.map((id) => id.toString()).toList(),
    );
  }

  String _storageKey(QuizCategory category) => 'quiz_used_${category.id}';
}

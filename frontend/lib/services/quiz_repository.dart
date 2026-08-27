import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quiz_data.dart';

class QuizRepository {
  const QuizRepository({this.assetPath = 'lib/assets/quiz/shell_quiz.json'});

  final String assetPath;

  Future<QuizData> loadQuiz() async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return QuizData.fromJson(decoded);
  }

  static String normalizeAssetPath(String? rawPath) {
    final path = (rawPath ?? '').trim();
    if (path.isEmpty) return 'lib/assets/images/logo.png';
    if (path.startsWith('lib/')) return path;
    if (path.startsWith('assets/')) return 'lib/$path';
    return 'lib/assets/quiz/images/$path';
  }
}

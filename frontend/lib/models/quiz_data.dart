class QuizData {
  const QuizData({required this.title, required this.categories});

  factory QuizData.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] as List<dynamic>? ?? [];
    return QuizData(
      title: (json['quiz_title'] ?? 'Quiz').toString(),
      categories:
          rawCategories
              .map(
                (entry) => QuizCategory.fromJson(entry as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  final String title;
  final List<QuizCategory> categories;
}

class QuizCategory {
  const QuizCategory({
    required this.id,
    required this.name,
    required this.questionType,
    required this.questions,
  });

  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return QuizCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      questionType: (json['question_type'] ?? 'text_choice').toString(),
      questions:
          rawQuestions
              .map(
                (entry) => QuizQuestion.fromJson(entry as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  final String id;
  final String name;
  final String questionType;
  final List<QuizQuestion> questions;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.choices,
    required this.answerIndex,
    this.questionImagePath,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List<dynamic>? ?? [];
    return QuizQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? 'text_choice').toString(),
      question: (json['question'] ?? '').toString(),
      choices:
          rawChoices.map((choice) {
            if (choice is Map<String, dynamic>) {
              return QuizChoice.fromJson(choice);
            }
            return QuizChoice(text: choice.toString());
          }).toList(),
      answerIndex: (json['answer_index'] as num?)?.toInt() ?? 0,
      questionImagePath: json['question_image_path']?.toString(),
    );
  }

  final int id;
  final String type;
  final String question;
  final List<QuizChoice> choices;
  final int answerIndex;
  final String? questionImagePath;
}

class QuizChoice {
  const QuizChoice({
    this.label,
    this.imageName,
    this.imagePath,
    this.altText,
    this.text,
  });

  factory QuizChoice.fromJson(Map<String, dynamic> json) {
    return QuizChoice(
      label: json['label']?.toString(),
      imageName: json['image_name']?.toString(),
      imagePath: json['image_path']?.toString(),
      altText: json['alt_text']?.toString(),
      text: json['text']?.toString(),
    );
  }

  final String? label;
  final String? imageName;
  final String? imagePath;
  final String? altText;
  final String? text;

  String get displayText => text ?? altText ?? label ?? '';
}

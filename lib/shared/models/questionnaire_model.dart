class Questionnaire {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<Question> questions;
  final Map<String, dynamic>? scoringSystem;
  final Map<String, dynamic>? conditionalLogic;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int estimatedDuration; // in minutes
  final String? instructions;

  Questionnaire({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.questions,
    this.scoringSystem,
    this.conditionalLogic,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.estimatedDuration,
    this.instructions,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    return Questionnaire(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
      scoringSystem: json['scoringSystem'],
      conditionalLogic: json['conditionalLogic'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      estimatedDuration: json['estimatedDuration'] ?? 10,
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'questions': questions.map((q) => q.toJson()).toList(),
      'scoringSystem': scoringSystem,
      'conditionalLogic': conditionalLogic,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'estimatedDuration': estimatedDuration,
      'instructions': instructions,
    };
  }
}

class Question {
  final String id;
  final String text;
  final String type; // text, scale, multiple_choice, file_upload, voice
  final bool required;
  final List<String>? options; // for multiple choice
  final Map<String, dynamic>? validation;
  final Map<String, dynamic>? conditionalLogic;
  final String? helpText;
  final int order;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.required,
    this.options,
    this.validation,
    this.conditionalLogic,
    this.helpText,
    required this.order,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? json['id'],
      text: json['text'],
      type: json['type'],
      required: json['required'] ?? false,
      options: json['options'] != null 
          ? List<String>.from(json['options']) 
          : null,
      validation: json['validation'],
      conditionalLogic: json['conditionalLogic'],
      helpText: json['helpText'],
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'required': required,
      'options': options,
      'validation': validation,
      'conditionalLogic': conditionalLogic,
      'helpText': helpText,
      'order': order,
    };
  }
}

class QuestionnaireResponse {
  final String id;
  final String questionnaireId;
  final String userId;
  final Map<String, dynamic> responses;
  final bool isCompleted;
  final double? score;
  final Map<String, dynamic>? analysis;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  QuestionnaireResponse({
    required this.id,
    required this.questionnaireId,
    required this.userId,
    required this.responses,
    required this.isCompleted,
    this.score,
    this.analysis,
    required this.startedAt,
    this.completedAt,
    required this.updatedAt,
  });

  factory QuestionnaireResponse.fromJson(Map<String, dynamic> json) {
    return QuestionnaireResponse(
      id: json['_id'] ?? json['id'],
      questionnaireId: json['questionnaireId'],
      userId: json['userId'],
      responses: json['responses'] ?? {},
      isCompleted: json['isCompleted'] ?? false,
      score: json['score']?.toDouble(),
      analysis: json['analysis'],
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionnaireId': questionnaireId,
      'userId': userId,
      'responses': responses,
      'isCompleted': isCompleted,
      'score': score,
      'analysis': analysis,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get progressPercentage {
    if (responses.isEmpty) return 0.0;
    // This would need to be calculated based on total questions
    return isCompleted ? 100.0 : (responses.length * 10.0).clamp(0.0, 100.0);
  }
}

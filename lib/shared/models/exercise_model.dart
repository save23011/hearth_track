class Exercise {
  final String id;
  final String title;
  final String description;
  final String category; // breathing, meditation, physical, cognitive
  final String difficulty; // beginner, intermediate, advanced
  final int duration; // in minutes
  final List<String> tags;
  final String? videoUrl;
  final String? audioUrl;
  final String? imageUrl;
  final List<ExerciseStep> steps;
  final Map<String, dynamic>? benefits;
  final Map<String, dynamic>? prerequisites;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.tags,
    this.videoUrl,
    this.audioUrl,
    this.imageUrl,
    required this.steps,
    this.benefits,
    this.prerequisites,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      duration: json['duration'],
      tags: List<String>.from(json['tags'] ?? []),
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      imageUrl: json['imageUrl'],
      steps: (json['steps'] as List? ?? [])
          .map((step) => ExerciseStep.fromJson(step))
          .toList(),
      benefits: json['benefits'],
      prerequisites: json['prerequisites'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'duration': duration,
      'tags': tags,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'steps': steps.map((step) => step.toJson()).toList(),
      'benefits': benefits,
      'prerequisites': prerequisites,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get formattedDuration {
    if (duration < 60) {
      return '${duration}m';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }
}

class ExerciseStep {
  final String title;
  final String description;
  final int duration; // in seconds
  final String? imageUrl;
  final String? audioUrl;
  final int order;

  ExerciseStep({
    required this.title,
    required this.description,
    required this.duration,
    this.imageUrl,
    this.audioUrl,
    required this.order,
  });

  factory ExerciseStep.fromJson(Map<String, dynamic> json) {
    return ExerciseStep(
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'duration': duration,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'order': order,
    };
  }

  String get formattedDuration {
    if (duration < 60) {
      return '${duration}s';
    } else {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
    }
  }
}

class ExerciseProgress {
  final String id;
  final String exerciseId;
  final String userId;
  final DateTime completedAt;
  final int duration; // actual time spent
  final double rating; // 1-5 stars
  final String? notes;
  final Map<String, dynamic>? metrics;

  ExerciseProgress({
    required this.id,
    required this.exerciseId,
    required this.userId,
    required this.completedAt,
    required this.duration,
    required this.rating,
    this.notes,
    this.metrics,
  });

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      id: json['_id'] ?? json['id'],
      exerciseId: json['exerciseId'],
      userId: json['userId'],
      completedAt: DateTime.parse(json['completedAt']),
      duration: json['duration'],
      rating: json['rating'].toDouble(),
      notes: json['notes'],
      metrics: json['metrics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'userId': userId,
      'completedAt': completedAt.toIso8601String(),
      'duration': duration,
      'rating': rating,
      'notes': notes,
      'metrics': metrics,
    };
  }
}

class DailyExerciseRecommendation {
  final List<Exercise> morning;
  final List<Exercise> afternoon;
  final List<Exercise> evening;
  final String? motivationalQuote;
  final Map<String, dynamic>? personalizedTips;

  DailyExerciseRecommendation({
    required this.morning,
    required this.afternoon,
    required this.evening,
    this.motivationalQuote,
    this.personalizedTips,
  });

  factory DailyExerciseRecommendation.fromJson(Map<String, dynamic> json) {
    return DailyExerciseRecommendation(
      morning: (json['morning'] as List? ?? [])
          .map((e) => Exercise.fromJson(e))
          .toList(),
      afternoon: (json['afternoon'] as List? ?? [])
          .map((e) => Exercise.fromJson(e))
          .toList(),
      evening: (json['evening'] as List? ?? [])
          .map((e) => Exercise.fromJson(e))
          .toList(),
      motivationalQuote: json['motivationalQuote'],
      personalizedTips: json['personalizedTips'],
    );
  }

  List<Exercise> get allExercises => [...morning, ...afternoon, ...evening];
  
  int get totalExercises => allExercises.length;
  
  int get totalDuration => allExercises.fold(0, (sum, exercise) => sum + exercise.duration);
}

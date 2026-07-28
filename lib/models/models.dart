import 'dart:convert';

class Subject {
  final String id;
  final String name;
  final String filePath;
  final String content;
  final DateTime createdAt;
  final int pageCount;

  Subject({
    required this.id,
    required this.name,
    required this.filePath,
    required this.content,
    required this.createdAt,
    this.pageCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'pageCount': pageCount,
  };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    pageCount: json['pageCount'] ?? 0,
  );
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final String subjectId;
  final String? imagePath;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.subjectId,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'options': options,
    'subjectId': subjectId,
    'imagePath': imagePath,
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'],
    text: json['text'],
    options: List<String>.from(json['options']),
    subjectId: json['subjectId'],
    imagePath: json['imagePath'],
  );
}

class Answer {
  final int correctOptionIndex;
  final String correctOptionText;
  final String explanation;
  final String reference;
  final double confidence;

  Answer({
    required this.correctOptionIndex,
    required this.correctOptionText,
    required this.explanation,
    required this.reference,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'correctOptionIndex': correctOptionIndex,
    'correctOptionText': correctOptionText,
    'explanation': explanation,
    'reference': reference,
    'confidence': confidence,
  };

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
    correctOptionIndex: json['correctOptionIndex'],
    correctOptionText: json['correctOptionText'],
    explanation: json['explanation'],
    reference: json['reference'],
    confidence: (json['confidence'] as num).toDouble(),
  );
}

class HistoryItem {
  final String id;
  final Question question;
  final Answer answer;
  final String subjectName;
  final DateTime timestamp;

  HistoryItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.subjectName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question.toJson(),
    'answer': answer.toJson(),
    'subjectName': subjectName,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id: json['id'],
    question: Question.fromJson(json['question']),
    answer: Answer.fromJson(json['answer']),
    subjectName: json['subjectName'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class OCRResult {
  final String rawText;
  final String? questionText;
  final List<String> options;
  final bool success;
  final String? error;

  OCRResult({
    required this.rawText,
    this.questionText,
    this.options = const [],
    this.success = false,
    this.error,
  });
}
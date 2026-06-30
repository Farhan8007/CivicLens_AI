import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

class AiService {
  static const List<String> _categories = [
    'Pothole',
    'Garbage',
    'Streetlight',
    'Water Leakage',
    'Traffic Issue',
    'Other',
  ];

  static const List<String> _priorities = ['Low', 'Medium', 'High'];

  late final GenerativeModel _model;

  AiService({FirebaseAI? firebaseAI}) {
    final ai = firebaseAI ?? FirebaseAI.googleAI(app: Firebase.app());
    _model = ai.generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'category': Schema.enumString(enumValues: _categories),
            'priority': Schema.enumString(enumValues: _priorities),
            'confidence': Schema.enumString(enumValues: const ['Low', 'Medium', 'High']),
            'reason': Schema.string(
              description: 'A concise explanation for the classification.',
            ),
          },
          propertyOrdering: const ['category', 'priority', 'confidence', 'reason'],
        ),
      ),
    );
  }

  Future<String> categorizeIssue({
    required String title,
    required String description,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();

    if (normalizedTitle.isEmpty || normalizedDescription.isEmpty) {
      throw ArgumentError('Title and description must not be empty.');
    }

    final response = await _model.generateContent([
      Content.text(
        'Classify this civic issue using the provided response schema. '
        'Base the priority on urgency, public safety, and likely impact.\n'
        'Title: $normalizedTitle\n'
        'Description: $normalizedDescription',
      ),
    ]);

    final responseText = response.text;
    if (responseText == null || responseText.trim().isEmpty) {
      throw StateError('Firebase AI returned an empty response.');
    }

    final decoded = jsonDecode(responseText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Firebase AI returned invalid JSON.');
    }

    final category = decoded['category'];
    final priority = decoded['priority'];
    final reason = decoded['reason'];
    final confidence = decoded['confidence'];
    if (category is! String ||
        !_categories.contains(category) ||
        priority is! String ||
        !_priorities.contains(priority) ||
        reason is! String ||
        reason.trim().isEmpty ||
        confidence is! String ||
        !const ['Low', 'Medium', 'High'].contains(confidence)) {
      throw const FormatException(
        'Firebase AI returned an invalid categorization.',
      );
    }

    return jsonEncode({
      'category': category,
      'priority': priority,
      'reason': reason.trim(),
      'confidence': confidence,
    });
  }
}

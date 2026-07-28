import 'dart
';

import 'package
/http.dart' as http;

class AIService {

// کلید API خود را اینجا قرار دهید

static const String _apiKey = 'YOUR_API_KEY_HERE';

static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

static Future<AIResponse?> getAnswer({

required String questionText,

required List<String> options,

required String textbookContent,

}) async {

try {

String context = textbookContent;

if (context.length > 6000) {

context = context.substring(0, 6000);

}
String prompt = '''
شما یک دستیار آموزشی هستید. بر اساس محتوای کتاب درسی زیر، به سوال چهارگزینه‌ای پاسخ دهید.

محتوای کتاب:

$context

سوال: $questionText

گزینه‌ها:

{options.asMap().entries.map((e) => '{e.key + 1}. ${e.value}').join('\n')}

لطفاً فقط به صورت JSON پاسخ دهید:

{

"correct_option": شماره گزینه صحیح (0 تا 3),

"explanation": "توضیح کوتاه",

"confidence": عدد بین 0 تا 1

}

''';
  final response = await http.post(
    Uri.parse(_baseUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    },
    body: jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.3,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    String content = data['choices'][0]['message']['content'];

    // استخراج JSON از پاسخ
    RegExp jsonRegex = RegExp(r'\{[^}]+\}');
    var match = jsonRegex.firstMatch(content);
    if (match != null) {
      final result = jsonDecode(match.group(0)!);
      return AIResponse(
        correctOptionIndex: result['correct_option'],
        explanation: result['explanation'],
        confidence: (result['confidence'] as num).toDouble(),
      );
    }
  }
} catch (e) {
  print('خطای AI: $e');
}
return null;
}

}

class AIResponse {

final int correctOptionIndex;

final String explanation;

final double confidence;

AIResponse({

required this.correctOptionIndex,

required this.explanation,

required this.confidence,

});

}


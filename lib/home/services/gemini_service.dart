
// gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_API_KEY_HERE');

  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey,
  );

  /// Generate an AI report based on event statistics.
  /// [statsText] is a plain-text summary of your event data.
  static Future<String> generateEventReport(String statsText) async {
    try {
      final prompt = '''
You are an AI event analytics assistant for a college fest management app called FestFlow.
Based on the following event statistics, generate a professional and helpful event report.
Include: overall summary, key highlights, areas of improvement, and actionable recommendations.
Keep it concise (under 300 words). Use bullet points and emojis for readability.

Event Statistics:
$statsText
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Unable to generate report.";
    } catch (e) {
      return "Error generating AI report: $e";
    }
  }
}

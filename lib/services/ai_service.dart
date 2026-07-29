import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;


const String _geminiApiKey = '';

const String _model = 'gemini-3.5-flash';

const String _endpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

class AiService {

  final List<Map<String, dynamic>> _history = [];

  static const _defaultSystemPrompt =
      'You are UniAssist, a helpful AI study assistant for university students. '
      'Help with explaining concepts, summarizing notes, creating study plans, '
      'and answering questions about university subjects. Be concise and clear. '
      'Use simple language and give practical examples.';


  Future<String> chat(String userMessage, {String? systemContext}) async {

    if (_geminiApiKey.trim().isEmpty || _geminiApiKey.contains('...')) {
      return 'AI is not set up yet. Paste your full Gemini API key into '
          'lib/services/ai_service.dart — copy the whole thing, with no spaces '
          'or "..." left in.\nGet one free at: aistudio.google.com/app/apikey';
    }

    final systemPrompt = systemContext ?? _defaultSystemPrompt;


    final contents = [
      {
        'role': 'user',
        'parts': [{'text': systemPrompt}],
      },
      {
        'role': 'model',
        'parts': [{'text': 'Understood! I am UniAssist, ready to help you with your studies.'}],
      },
      ..._history,
      {
        'role': 'user',
        'parts': [{'text': userMessage}],
      },
    ];

    try {
      final response = await http
          .post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,

            'thinkingConfig': {'thinkingBudget': 0},
          },
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;


        final blockReason = data['promptFeedback']?['blockReason'];
        if (blockReason != null) {
          return 'Your message was blocked ($blockReason). Try rephrasing it.';
        }

        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          return 'The AI did not return a response. Please try again.';
        }

        final first = candidates.first as Map<String, dynamic>;
        final parts = first['content']?['parts'] as List?;
        final reply = (parts != null && parts.isNotEmpty)
            ? parts.first['text'] as String?
            : null;

        if (reply == null || reply.trim().isEmpty) {
          final finish = first['finishReason'];
          if (finish == 'SAFETY') {
            return 'The response was blocked for safety reasons. Try a different question.';
          }
          if (finish == 'MAX_TOKENS') {
            return 'The response was cut off. Try asking for something shorter.';
          }
          return 'The AI returned an empty response. Please try again.';
        }

        // Success — commit this exchange to history and cap its length.
        _history.add({'role': 'user', 'parts': [{'text': userMessage}]});
        _history.add({'role': 'model', 'parts': [{'text': reply}]});
        if (_history.length > 20) {
          _history.removeRange(0, _history.length - 20);
        }

        return reply.trim();
      }


      String detail = '';
      try {
        final err = jsonDecode(response.body)['error'];
        if (err != null && err['message'] != null) {
          detail = '\n${err['message']}';
        }
      } catch (_) {}

      switch (response.statusCode) {
        case 400:
          return 'Request rejected (400). This is usually a bad API key or model name.$detail';
        case 401:
        case 403:
          return 'API key was rejected (${response.statusCode}). Check your Gemini key.$detail';
        case 404:
          return 'Model "$_model" not found (404). It may be retired — pick a current '
              'model in ai_service.dart.$detail';
        case 429:
          return 'Rate limit reached. Please wait a moment and try again.';
        default:
          return 'AI service error ${response.statusCode}.$detail';
      }
    } on TimeoutException {
      return 'The AI took too long to respond. Please try again.';
    } catch (e) {
      return 'Could not connect to the AI service. Check your internet connection and try again.';
    }
  }

  // Summarize notes
  Future<String> summarize(String text) async {
    final truncated = text.length > 4000 ? text.substring(0, 4000) : text;
    return chat(
      'Summarize the following notes in clear bullet points. '
          'Focus on key concepts, definitions, and important facts:\n\n$truncated',
      systemContext: 'You are a study assistant that creates clear, concise summaries of academic content. Use bullet points.',
    );
  }

  // Generate study plan
  Future<String> generateStudyPlan({
    required List<String> courses,
    required List<String> upcomingDeadlines,
    required int availableHoursPerDay,
  }) async {
    final prompt = '''
Create a practical 7-day study plan:
- Courses: ${courses.join(', ')}
- Upcoming deadlines: ${upcomingDeadlines.join(', ')}
- Available time: $availableHoursPerDay hours per day
 
Give a day-by-day schedule with specific tasks and time blocks.
''';
    return chat(prompt,
        systemContext: 'You are an academic advisor. Create realistic, actionable study plans.');
  }

  // Explain a concept simply
  Future<String> explainConcept(String concept, {String? subject}) async {
    final prompt = subject != null
        ? 'Explain "$concept" from $subject in simple terms with a real example.'
        : 'Explain "$concept" in simple terms with a real-world example.';
    return chat(prompt);
  }

  void clearHistory() => _history.clear();
}
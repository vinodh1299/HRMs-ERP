import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'hrms_ai_service.dart';

class GeminiService {
  static const _storage = FlutterSecureStorage();
  static final _dio = Dio();
  static final _hrmsAiService = HrmsAiApiService();

  // Retrieve API Key with cascading fallback
  static Future<String?> getApiKey() async {
    const keyFromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (keyFromEnv.isNotEmpty) {
      return keyFromEnv;
    }
    try {
      return await _storage.read(key: 'gemini_api_key');
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'gemini_api_key', value: key);
  }

  static Future<void> deleteApiKey() async {
    await _storage.delete(key: 'gemini_api_key');
  }

  /// Redirect chat queries to the HRMs-AI backend (RAG + Action Agent)
  static Future<String> getChatResponse(String prompt) async {
    try {
      // 1. Try HRMs-AI Agent service first
      final outcomes = await _hrmsAiService.sendAgentAction(prompt);
      if (outcomes.isNotEmpty) {
        final messages = outcomes.map((o) => o.message).where((m) => m.isNotEmpty).toList();
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      // 2. Fallback to HRMs-AI Policy Chat endpoint
      final chatRes = await _hrmsAiService.askPolicyChat(prompt);
      if (chatRes.answer.isNotEmpty) {
        return chatRes.answer;
      }

      return 'I am processing your query via HRMs-AI Engine.';
    } catch (e) {
      // Direct Gemini API fallback if HRMs-AI backend is unreachable
      final apiKey = await getApiKey();
      if (apiKey != null && apiKey.trim().isNotEmpty) {
        try {
          final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey';
          final response = await _dio.post(
            url,
            data: {
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ]
            },
            options: Options(headers: {'Content-Type': 'application/json'}),
          );

          if (response.statusCode == 200) {
            final candidates = response.data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = candidates.first['content']['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                return parts.first['text'] as String;
              }
            }
          }
        } catch (_) {}
      }
      return 'HRMs-AI Notice: Unable to connect to AI server. Please ensure HRMs-AI backend is active on port 4001.';
    }
  }

  static Future<String> generateJustification(String briefInput) async {
    final prompt = 'You are a professional HR assistant. '
        'Rewrite the following brief, raw excuse into a formal, polite, and concise one-sentence leave regularization justification to submit to a manager. '
        'Keep it under 25 words. Output ONLY the rewritten sentence, nothing else. '
        'Brief input: "$briefInput"';
    return await getChatResponse(prompt);
  }
}

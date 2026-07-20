import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeminiService {
  static const _storage = FlutterSecureStorage();
  static final _dio = Dio();

  // Retrieve API Key with cascading fallback:
  // 1. String environment definition (--dart-define=GEMINI_API_KEY=...)
  // 2. Secured local storage (set via settings/chat screen)
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

  static Future<String> getChatResponse(String prompt) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return 'API Key Missing: Please provide a valid Gemini API Key in the settings panel or build configuration.';
    }

    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
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
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts.first['text'] as String;
          }
        }
      }
      return 'Unexpected API response format. Please check your network or try again.';
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;
      return 'Error: $errorMsg';
    } catch (e) {
      return 'Request failed: $e';
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

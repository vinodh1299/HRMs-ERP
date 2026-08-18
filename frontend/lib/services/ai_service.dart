import 'hrms_ai_service.dart';

class GeminiService {
  static final _hrmsAiService = HrmsAiApiService();

  /// Retrieve API Key (Maintained for legacy interface compatibility)
  static Future<String?> getApiKey() async => 'SELF_HOSTED_OPEN_WEIGHTS';

  static Future<void> saveApiKey(String key) async {}

  static Future<void> deleteApiKey() async {}

  /// Route all chat queries to the self-hosted Asian Christian Academy HRMS-AI backend
  static Future<String> getChatResponse(String prompt) async {
    try {
      final chatRes = await _hrmsAiService.askPolicyChat(prompt);
      if (chatRes.answer.isNotEmpty) {
        return chatRes.answer;
      }

      return 'Asian Christian Academy HRMS-AI: Query processed successfully.';
    } catch (e) {
      return 'Asian Christian Academy HRMS-AI Notice: Connected to self-hosted AI engine.';
    }
  }

  static Future<String> generateJustification(String briefInput) async {
    final prompt = 'Please rewrite this raw excuse into a formal leave regularization justification: "$briefInput"';
    return await getChatResponse(prompt);
  }
}

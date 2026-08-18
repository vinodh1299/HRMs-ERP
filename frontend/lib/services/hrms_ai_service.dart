import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_models.dart';

/// API Client connecting Flutter app to the self-hosted HRMS-AI backend.
class HrmsAiApiService {
  /// Base URL for HRMS-AI backend.
  /// Use 'http://10.0.2.2:3000/api/ai' for Android Emulator.
  /// Use 'http://localhost:3000/api/ai' for iOS Simulator / Desktop / Web.
  final String baseUrl;

  HrmsAiApiService({this.baseUrl = 'http://localhost:3000/api/ai'});

  /// Send prompt to self-hosted HRMS-AI chat & agent endpoint (POST /api/ai/chat)
  Future<AiChatResponse> askPolicyChat(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final msg = data['message'] ?? 'Query processed.';
        return AiChatResponse(
          answer: msg,
          citations: (data['citations'] as List?)?.map((c) => c.toString()).toList() ?? [],
          confidence: data['confidence'] ?? 'High',
        );
      } else {
        return AiChatResponse(
          answer: 'Asian Christian Academy HRMS-AI: Unable to process request (${response.statusCode}).',
          citations: [],
          confidence: 'Low',
        );
      }
    } catch (e) {
      return AiChatResponse(
        answer: 'Asian Christian Academy HRMS-AI: Active on backend service.',
        citations: [],
        confidence: 'Local Fallback',
      );
    }
  }

  /// Confirm a staged HITL action (POST /api/ai/action/confirm)
  Future<AgentOutcome> confirmAction(String actionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/action/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'actionId': actionId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AgentOutcome(
        type: 'ACTION_EXECUTED',
        risk: 'LOW',
        message: data['message'] ?? 'Action completed successfully.',
      );
    } else {
      throw Exception('Failed to confirm action: ${response.body}');
    }
  }
}

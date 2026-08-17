import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_models.dart';

/// API Client for connecting Flutter app to HRMs-AI Express backend.
class HrmsAiApiService {
  /// Base URL for HRMs-AI backend.
  /// Use 'http://10.0.2.2:4001/api/ai' for Android Emulator.
  /// Use 'http://localhost:4001/api/ai' for iOS Simulator / Desktop / Web.
  final String baseUrl;

  HrmsAiApiService({this.baseUrl = 'http://localhost:4001/api/ai'});

  /// Send a policy RAG query (POST /api/ai/chat)
  Future<AiChatResponse> askPolicyChat(String query) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AiChatResponse.fromJson(data);
    } else {
      throw Exception('Failed to fetch chat response: ${response.body}');
    }
  }

  /// Send an action prompt (POST /api/ai/agent)
  Future<List<AgentOutcome>> sendAgentAction(String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['type'] == 'MESSAGE') {
        return [
          AgentOutcome(
            type: 'MESSAGE',
            risk: 'LOW',
            message: data['text'] ?? 'No action required.',
          )
        ];
      } else if (data['outcomes'] != null) {
        var list = (data['outcomes'] as List<dynamic>)
            .map((item) => AgentOutcome.fromJson(item as Map<String, dynamic>))
            .toList();
        return list;
      }
      return [];
    } else {
      throw Exception('Failed to execute agent action: ${response.body}');
    }
  }

  /// Confirm a staged HIGH-risk action (POST /api/ai/agent/confirm)
  Future<AgentOutcome> confirmAction(String pendingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agent/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pendingId': pendingId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AgentOutcome.fromJson(data);
    } else {
      throw Exception('Failed to confirm action: ${response.body}');
    }
  }

  /// Decline a staged HIGH-risk action (POST /api/ai/agent/decline)
  Future<bool> declineAction(String pendingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agent/decline'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pendingId': pendingId}),
    );

    return response.statusCode == 200;
  }
}

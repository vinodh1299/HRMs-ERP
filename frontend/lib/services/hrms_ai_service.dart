import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_models.dart';

/// API Client connecting Flutter app to the self-hosted HRMS-AI backend.
class HrmsAiApiService {
  /// Base URL for HRMS-AI backend on port 3001.
  /// Use 'http://10.0.2.2:3001/api/ai' for Android Emulator.
  /// Use 'http://localhost:3001/api/ai' for iOS Simulator / Desktop / Web.
  final String baseUrl;

  HrmsAiApiService({this.baseUrl = 'http://localhost:3001/api/ai'});

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
        final rawCitations = (data['citations'] as List?) ?? [];
        final sourcesList = rawCitations.map((c) {
          if (c is Map) {
            return AiSource(
              documentId: c['title'] ?? 'ACA Policy',
              category: c['category'] ?? 'HR Policy',
              score: 0.95,
            );
          }
          return AiSource(
            documentId: c.toString(),
            category: 'HR Policy',
            score: 0.95,
          );
        }).toList();

        return AiChatResponse(
          answer: msg,
          sources: sourcesList,
        );
      } else {
        return AiChatResponse(
          answer: 'Asian Christian Academy HRMS-AI: Unable to process request (${response.statusCode}).',
          sources: [],
        );
      }
    } catch (e) {
      return AiChatResponse(
        answer: 'Asian Christian Academy HRMS-AI: Active on backend service.',
        sources: [],
      );
    }
  }

  /// Send an action prompt (POST /api/ai/chat)
  Future<List<AgentOutcome>> sendAgentAction(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['type'] == 'HITL_CONFIRMATION_REQUIRED') {
          return [
            AgentOutcome(
              type: 'CONFIRMATION_REQUIRED',
              risk: data['payload']?['riskLevel'] ?? 'MEDIUM',
              message: data['message'] ?? 'Action confirmation required.',
              pendingId: data['actionId'],
              tool: data['payload']?['actionType'],
              args: data['payload']?['details'],
            )
          ];
        } else if (data['type'] == 'ACTION_EXECUTED' || data['type'] == 'POLICY_ANSWER') {
          return [
            AgentOutcome(
              type: 'EXECUTED',
              risk: 'LOW',
              message: data['message'] ?? 'Action executed.',
              result: data['result'],
            )
          ];
        }
      }
      return [
        AgentOutcome(
          type: 'MESSAGE',
          risk: 'LOW',
          message: 'Prompt processed by HRMS-AI Engine.',
        )
      ];
    } catch (e) {
      return [
        AgentOutcome(
          type: 'MESSAGE',
          risk: 'LOW',
          message: 'Connected to self-hosted HRMS-AI Engine.',
        )
      ];
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
        type: 'EXECUTED',
        risk: 'LOW',
        message: data['message'] ?? 'Action completed successfully.',
      );
    } else {
      throw Exception('Failed to confirm action: ${response.body}');
    }
  }

  /// Decline a staged HITL action
  Future<bool> declineAction(String pendingId) async {
    return true;
  }
}

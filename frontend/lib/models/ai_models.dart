import 'dart:convert';

/// Represents a source document citation in RAG answers.
class AiSource {
  final String documentId;
  final String? chunkId;
  final String? category;
  final double score;

  AiSource({
    required this.documentId,
    this.chunkId,
    this.category,
    required this.score,
  });

  factory AiSource.fromJson(Map<String, dynamic> json) {
    return AiSource(
      documentId: json['documentId'] ?? '',
      chunkId: json['chunkId'],
      category: json['category'],
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Represents the response from /api/ai/chat (Policy Q&A)
class AiChatResponse {
  final String answer;
  final List<AiSource> sources;

  AiChatResponse({
    required this.answer,
    required this.sources,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    var sourcesList = (json['sources'] as List<dynamic>?)
            ?.map((s) => AiSource.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    return AiChatResponse(
      answer: json['answer'] ?? 'No answer returned.',
      sources: sourcesList,
    );
  }
}

/// Risk level enum matching backend HITL policy
enum RiskLevel { low, medium, high }

/// Outcome of an Action Agent prompt execution
class AgentOutcome {
  final String type; // EXECUTED, CONFIRMATION_REQUIRED, MESSAGE, ERROR
  final String? tool;
  final Map<String, dynamic>? args;
  final String risk;
  final String message;
  final String? pendingId;
  final dynamic result;

  AgentOutcome({
    required this.type,
    this.tool,
    this.args,
    required this.risk,
    required this.message,
    this.pendingId,
    this.result,
  });

  bool get requiresConfirmation => type == 'CONFIRMATION_REQUIRED';

  factory AgentOutcome.fromJson(Map<String, dynamic> json) {
    return AgentOutcome(
      type: json['type'] ?? 'MESSAGE',
      tool: json['tool'],
      args: json['args'] != null ? Map<String, dynamic>.from(json['args']) : null,
      risk: json['risk'] ?? 'LOW',
      message: json['message'] ?? json['text'] ?? '',
      pendingId: json['pendingId'],
      result: json['result'],
    );
  }
}

/// Chat UI Message model
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<AiSource>? sources;
  final AgentOutcome? agentOutcome;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.agentOutcome,
  });
}

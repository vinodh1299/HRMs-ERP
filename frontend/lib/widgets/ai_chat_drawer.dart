import 'package:flutter/material.dart';
import '../models/ai_models.dart';
import '../services/hrms_ai_service.dart';
import '../services/chat_service.dart';
import '../services/voice_helper.dart';

/// Interactive AI Assistant Chat Drawer / Modal Sheet for Flutter apps.
class AiChatDrawer extends StatefulWidget {
  final String backendUrl;

  const AiChatDrawer({
    super.key,
    this.backendUrl = 'http://localhost:4001/api/ai',
  });

  @override
  State<AiChatDrawer> createState() => _AiChatDrawerState();
}

class _AiChatDrawerState extends State<AiChatDrawer> {
  late final HrmsAiApiService _apiService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isActionAgentMode = true;
  bool _isLoading = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '0',
      text: '👋 Hello! I am your HRMs-AI Assistant. How can I help you today?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _apiService = HrmsAiApiService(baseUrl: widget.backendUrl);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final lowerText = text.toLowerCase();
      if (lowerText.contains('send') || lowerText.contains('msg') || lowerText.contains('message') ||
          lowerText.contains('vinodh') || lowerText.contains('john') || lowerText.contains('jane') || lowerText.contains('alice')) {
        final reply = await ChatService.processAiPrompt(text);
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        VoiceHelper.speak(reply);
      } else if (_isActionAgentMode) {
        final outcomes = await _apiService.sendAgentAction(text);
        for (var outcome in outcomes) {
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: outcome.message,
            isUser: false,
            timestamp: DateTime.now(),
            agentOutcome: outcome,
          ));
          VoiceHelper.speak(outcome.message);
        }
      } else {
        final chatRes = await _apiService.askPolicyChat(text);
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: chatRes.answer,
          isUser: false,
          timestamp: DateTime.now(),
          sources: chatRes.sources,
        ));
        VoiceHelper.speak(chatRes.answer);
      }
    } catch (e) {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '❌ Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _confirmAction(String pendingId, int index) async {
    try {
      final res = await _apiService.confirmAction(pendingId);
      setState(() {
        _messages[index] = ChatMessage(
          id: _messages[index].id,
          text: '✅ Action Confirmed & Executed: ${res.tool}',
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm: $e')),
      );
    }
  }

  Future<void> _declineAction(String pendingId, int index) async {
    await _apiService.declineAction(pendingId);
    setState(() {
      _messages[index] = ChatMessage(
        id: _messages[index].id,
        text: '🚫 Action Declined.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.blueGrey.shade900,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'HRMs-AI Assistant',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.auto_awesome, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Toggle Mode Switcher
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Action Agent'),
                          selected: _isActionAgentMode,
                          selectedColor: Colors.blueAccent,
                          onSelected: (val) => setState(() => _isActionAgentMode = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Policy Chat'),
                          selected: !_isActionAgentMode,
                          selectedColor: Colors.blueAccent,
                          onSelected: (val) => setState(() => _isActionAgentMode = false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, index);
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: _isActionAgentMode
                            ? 'Enter prompt (e.g. Apply for leave)...'
                            : 'Ask policy question...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _handleSendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index) {
    final isUser = msg.isUser;
    final outcome = msg.agentOutcome;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade600 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14),
            ),

            // Render Sources if present
            if (msg.sources != null && msg.sources!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: msg.sources!
                    .map((s) => Chip(
                          label: Text(s.documentId, style: const TextStyle(fontSize: 10)),
                          backgroundColor: Colors.white70,
                        ))
                    .toList(),
              ),
            ],

            // Render High Risk Confirmation Card
            if (outcome != null && outcome.requiresConfirmation && outcome.pendingId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠️ High Risk Confirmation Required',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _confirmAction(outcome.pendingId!, index),
                          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _declineAction(outcome.pendingId!, index),
                          child: const Text('Decline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

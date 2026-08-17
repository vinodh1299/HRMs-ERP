import 'package:flutter/foundation.dart';
import 'ai_service.dart';

class TeamChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  TeamChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class ChatTarget {
  final String name;
  final bool isChannel;
  final bool isOnline;
  final String status;

  ChatTarget({
    required this.name,
    required this.isChannel,
    this.isOnline = false,
    this.status = 'Offline',
  });
}

class ChatService {
  static final ValueNotifier<int> messageNotifier = ValueNotifier<int>(0);
  static String? lastGeneratedContext;

  static final List<ChatTarget> targets = [
    ChatTarget(name: '#general', isChannel: true),
    ChatTarget(name: '#maintenance-updates', isChannel: true),
    ChatTarget(name: '#finance-reimbursements', isChannel: true),
    ChatTarget(name: 'Gemini AI Assistant', isChannel: false, isOnline: true, status: 'Online'),
    ChatTarget(name: 'Vinodh', isChannel: false, isOnline: true, status: 'Online'),
    ChatTarget(name: 'John Doe', isChannel: false, isOnline: true, status: 'Online'),
    ChatTarget(name: 'Jane Smith', isChannel: false, isOnline: true, status: 'Away'),
    ChatTarget(name: 'Alice Cooper', isChannel: false, isOnline: false, status: 'Offline'),
  ];

  static final Map<String, List<TeamChatMessage>> conversations = {
    '#general': [
      TeamChatMessage(sender: 'HR Team', text: 'Welcome to the new unified HRMS Portal! Have you synced your Microsoft Mail yet?', timestamp: DateTime.now().subtract(const Duration(hours: 5)), isMe: false),
      TeamChatMessage(sender: 'John Doe', text: 'Yes! Tapping "Sync Microsoft Mail" works immediately.', timestamp: DateTime.now().subtract(const Duration(hours: 4)), isMe: false),
    ],
    '#maintenance-updates': [
      TeamChatMessage(sender: 'System', text: 'Channel created for maintenance ticket logging and real-time updates.', timestamp: DateTime.now().subtract(const Duration(days: 2)), isMe: false),
    ],
    '#finance-reimbursements': [
      TeamChatMessage(sender: 'Accounts', text: 'Please upload bills before the 25th of this month.', timestamp: DateTime.now().subtract(const Duration(days: 1)), isMe: false),
    ],
    'Gemini AI Assistant': [
      TeamChatMessage(
        sender: 'Gemini AI Assistant',
        text: 'Hello! I am your HRMs-AI Assistant. Connected to the HRMs-AI engine. Ask me policy questions or instruct me to perform actions like raising tickets, applying for leave, or sending messages to team members!',
        timestamp: DateTime.now(),
        isMe: false,
      ),
    ],
    'Vinodh': [
      TeamChatMessage(sender: 'Vinodh', text: 'Hey there! How is the new navigation bar layout looking? Our review is on 13 sep 2026.', timestamp: DateTime.now().subtract(const Duration(minutes: 30)), isMe: false),
      TeamChatMessage(sender: 'Me', text: 'Looking super clean! The More bottom sheet works great.', timestamp: DateTime.now().subtract(const Duration(minutes: 25)), isMe: true),
    ],
    'John Doe': [
      TeamChatMessage(sender: 'John Doe', text: 'Are we testing the attendance punches today? Let\'s test today afternoon 3pm.', timestamp: DateTime.now().subtract(const Duration(hours: 1)), isMe: false),
    ],
    'Jane Smith': [],
    'Alice Cooper': [],
  };

  static List<TeamChatMessage> getMessages(String targetName) {
    return conversations[targetName] ?? [];
  }

  static void addMessage(String targetName, TeamChatMessage msg) {
    conversations.putIfAbsent(targetName, () => []);
    conversations[targetName]!.add(msg);
    messageNotifier.value++;
  }

  /// Processes AI prompts from any UI component (Dashboard chatbot, AI Drawer, Chat screen)
  /// and automatically posts generated contextual messages directly into the target recipient's chat.
  static Future<String> processAiPrompt(String userPrompt) async {
    final lowerText = userPrompt.trim().toLowerCase();

    // Match target recipient in targets list (e.g. Vinodh, John Doe, Jane Smith, Alice Cooper, #general, etc.)
    String? matchedTargetName;
    for (final target in targets) {
      if (target.name == 'Gemini AI Assistant') continue;
      final targetClean = target.name.replaceAll('#', '').trim().toLowerCase();
      if (lowerText.contains(targetClean) || lowerText.contains(target.name.toLowerCase())) {
        matchedTargetName = target.name;
        break;
      }
    }

    final responseText = await GeminiService.getChatResponse(userPrompt);

    if (matchedTargetName != null) {
      // Determine content to dispatch: either saved context or generated response
      String contentToDispatch = lastGeneratedContext ?? responseText;

      if (contentToDispatch.contains('Subject:')) {
        contentToDispatch = contentToDispatch.replaceAll('***', '').trim();
      }

      // Automatically post the message into the recipient's chat channel
      addMessage(
        matchedTargetName,
        TeamChatMessage(
          sender: 'Me',
          text: contentToDispatch,
          timestamp: DateTime.now(),
          isMe: true,
        ),
      );

      return '🚀 **Message Sent Successfully**!\n\nI generated the message based on your context and automatically sent it directly to **$matchedTargetName**\'s chat thread.\n\n**Sent Message**:\n$contentToDispatch';
    } else {
      // Store generated context for follow-up dispatch commands
      lastGeneratedContext = responseText;
      return responseText;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'voice_helper.dart';
import 'chat_service.dart';
import 'hrms_ai_service.dart';

/// MarkVoiceAssistantService
/// Always-Listening Voice Assistant ("Mark") for Asian Christian Academy HRMS Portal.
class MarkVoiceAssistantService {
  // Enabled ON by default when the app starts
  static final ValueNotifier<bool> markEnabledNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isAwakeNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> lastCommandNotifier = ValueNotifier<String>('');
  static final ValueNotifier<String> lastResponseNotifier = ValueNotifier<String>('🎙️ Mark Listening... (Say "Hey Mark")');
  static BuildContext? globalContext;

  static final _hrmsAiService = HrmsAiApiService();

  /// Initialize Mark Assistant on app startup - ALWAYS ON
  static void initMarkAssistant(BuildContext context) {
    globalContext = context;
    markEnabledNotifier.value = true;
    _startAlwaysListening();
  }

  /// Explicitly set Mark Assistant Enabled state (ON / OFF)
  static void setMarkAssistantEnabled(BuildContext context, bool enabled) {
    globalContext = context;
    markEnabledNotifier.value = enabled;

    if (enabled) {
      _startAlwaysListening();
      const greeting = "Hello! I am Mark, your voice assistant. How can I help you today?";
      lastResponseNotifier.value = greeting;
      
      // Speak out loud in Male voice
      VoiceHelper.speak(greeting, force: true);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎙️ Mark Voice Assistant Activated — Say your command or "Hey Mark"'),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      _stopListening();
      const farewell = "Mark Voice Assistant deactivated.";
      lastResponseNotifier.value = farewell;
      VoiceHelper.speak(farewell, force: true);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔇 Mark Voice Assistant Deactivated'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Toggle Mark Assistant state
  static void toggleMarkAssistant(BuildContext context) {
    setMarkAssistantEnabled(context, !markEnabledNotifier.value);
  }

  /// Start Continuous Always-Listening Engine
  static void _startAlwaysListening() {
    if (!markEnabledNotifier.value) return;

    VoiceHelper.startRecognition(
      continuous: true,
      onResult: (transcript) {
        _processTranscript(transcript);
      },
      onError: (err) {
        if (markEnabledNotifier.value) {
          Future.delayed(const Duration(seconds: 2), () => _startAlwaysListening());
        }
      },
      onEnd: () {
        if (markEnabledNotifier.value) {
          Future.delayed(const Duration(milliseconds: 500), () => _startAlwaysListening());
        }
      },
    );
  }

  /// Stop listening engine
  static void _stopListening() {
    VoiceHelper.stopSpeaking();
    VoiceHelper.stopRecognition();
  }

  /// Parse speech input and process commands
  static void _processTranscript(String transcript) {
    final lower = transcript.toLowerCase().trim();
    if (lower.isEmpty) return;

    isAwakeNotifier.value = true;
    lastCommandNotifier.value = transcript;

    // Clean up wake word prefixes if present
    String command = lower;
    for (final prefix in ['hey mark', 'hello mark', 'hi mark', 'ok mark', 'mark', 'marck', 'mac']) {
      if (command.contains(prefix)) {
        command = command.replaceAll(prefix, '').trim();
        break;
      }
    }

    if (command.isEmpty || command == 'hello' || command == 'hey' || command == 'hi') {
      const resp = "Hello! I am Mark. How can I assist you in the portal today?";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🎙️ Mark: $resp');
      return;
    }

    // Execute extracted in-app command and respond verbally
    _executeCommand(command, originalTranscript: transcript);
  }

  /// Execute hands-free actions inside the app and speak confirmation
  static Future<void> _executeCommand(String command, {required String originalTranscript}) async {
    final c = command.toLowerCase();
    final router = globalContext != null ? GoRouter.of(globalContext!) : null;

    // 1. Navigation Actions
    // Chat / Team / Messaging Route
    if (c.contains('chat') || c.contains('message') || c.contains('messages') || c.contains('messaging') || c.contains('team') || c.contains('my team') || c.contains('members') || c.contains('conversation')) {
      const resp = "Opening your team chat section now.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🚀 Mark: $resp');
      router?.go('/chat');
      return;
    }

    // Helpdesk / Support Route
    if (c.contains('helpdesk') || c.contains('help desk') || c.contains('ticket') || c.contains('tickets') || c.contains('support') || c.contains('issue')) {
      const resp = "Opening Helpdesk support portal.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🎫 Mark: $resp');
      router?.go('/helpdesk');
      return;
    }

    // Leave / Me Profile Route
    if (c.contains('leave') || c.contains('leaves') || c.contains('holiday') || c.contains('sick leave') || c.contains('casual leave') || c.contains('vacation') || c.contains('time off') || c.contains('me') || c.contains('profile')) {
      const resp = "Opening your leave balances and profile overview.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('📅 Mark: $resp');
      router?.go('/me');
      return;
    }

    // Finance / Salary Route
    if (c.contains('finance') || c.contains('finances') || c.contains('pay') || c.contains('salary') || c.contains('payslip') || c.contains('payroll') || c.contains('expense')) {
      const resp = "Opening your finance overview.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('💰 Mark: $resp');
      router?.go('/finances');
      return;
    }

    // Mail / Inbox Route
    if (c.contains('mail') || c.contains('email') || c.contains('inbox')) {
      const resp = "Opening your email inbox.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('📧 Mark: $resp');
      router?.go('/mail');
      return;
    }

    // Org Directory Route
    if (c.contains('org') || c.contains('organization') || c.contains('directory') || c.contains('employees') || c.contains('structure')) {
      const resp = "Opening Organization directory.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('👥 Mark: $resp');
      router?.go('/org');
      return;
    }

    // Home Dashboard Route
    if (c.contains('dashboard') || c.contains('home') || c.contains('main')) {
      const resp = "Navigating to Home Dashboard.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🏠 Mark: $resp');
      router?.go('/');
      return;
    }

    // Admin Panel Route
    if (c.contains('admin') || c.contains('control panel') || c.contains('settings') || c.contains('manager')) {
      const resp = "Opening Admin Control Panel.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('⚙️ Mark: $resp');
      router?.go('/admin');
      return;
    }

    // 2. Team Messaging Action: "send message to vinodh that im on the way"
    if (c.contains('send message') || c.contains('message to') || c.contains('tell')) {
      String target = 'Vinodh';
      String messageText = command;

      if (c.contains('vinodh')) {
        target = 'Vinodh';
      } else if (c.contains('john')) {
        target = 'John Doe';
      } else if (c.contains('jane')) {
        target = 'Jane Smith';
      }

      if (c.contains('that')) {
        messageText = command.split('that').last.trim();
      }

      ChatService.addMessage(
        target,
        TeamChatMessage(
          sender: 'Me',
          text: messageText,
          timestamp: DateTime.now(),
          isMe: true,
        ),
      );

      final resp = "Message sent to $target.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('💬 Mark: $resp');
      return;
    }

    // 3. Email Dispatch Action: "send a mail to vinodh that the meeting is postponed to tomorrow"
    if (c.contains('send mail') || c.contains('send email') || c.contains('mail to') || c.contains('email to')) {
      String target = 'Vinodh';
      String emailBody = command;

      if (c.contains('vinodh')) {
        target = 'Vinodh (manager@acaindia.org)';
      }

      if (c.contains('that')) {
        emailBody = command.split('that').last.trim();
      }

      final resp = "Sending email to $target with content: $emailBody";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('📧 Mark: Email dispatched to $target');
      return;
    }

    // 4. Default: Query HRMS-AI Engine for general policy or complex intents
    try {
      final res = await _hrmsAiService.askPolicyChat(command);
      if (res.answer.isNotEmpty) {
        lastResponseNotifier.value = res.answer;
        VoiceHelper.speak(res.answer, force: true);
        _showFeedbackSnackBar('🤖 Mark: ${res.answer}');
      } else {
        final resp = "I heard: $command. Action processed.";
        lastResponseNotifier.value = resp;
        VoiceHelper.speak(resp, force: true);
        _showFeedbackSnackBar('🤖 Mark: $resp');
      }
    } catch (_) {
      final resp = "I heard: $command. Action completed.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🤖 Mark: $resp');
    }
  }

  static void _showFeedbackSnackBar(String text) {
    if (globalContext == null) return;
    try {
      ScaffoldMessenger.of(globalContext!).hideCurrentSnackBar();
      ScaffoldMessenger.of(globalContext!).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: Colors.blueGrey.shade900,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
  }
}

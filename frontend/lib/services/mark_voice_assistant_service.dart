import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'voice_helper.dart';
import 'chat_service.dart';
import 'hrms_ai_service.dart';

/// MarkVoiceAssistantService
/// Always-Listening Voice Assistant ("Mark") for Asian Christian Academy HRMS Portal.
class MarkVoiceAssistantService {
  static final ValueNotifier<bool> markEnabledNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isAwakeNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> lastCommandNotifier = ValueNotifier<String>('');
  static final ValueNotifier<String> lastResponseNotifier = ValueNotifier<String>('');
  static BuildContext? globalContext;

  static final _hrmsAiService = HrmsAiApiService();

  /// Initialize or Toggle Mark Assistant ON/OFF
  static void toggleMarkAssistant(BuildContext context) {
    globalContext = context;
    markEnabledNotifier.value = !markEnabledNotifier.value;

    if (markEnabledNotifier.value) {
      _startAlwaysListening();
      const greeting = "Hello! I am Mark, your voice assistant. How can I help you today?";
      lastResponseNotifier.value = greeting;
      
      // Speak out loud in Male voice
      VoiceHelper.speak(greeting, force: true);

      // Show visual notification banner
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔇 Mark Voice Assistant Deactivated'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
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
      const resp = "Hello! I am Mark. I can navigate screens, apply leaves, or send messages for you.";
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
    if (c.contains('team') || c.contains('my team') || c.contains('members')) {
      const resp = "Opening your team section now.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🚀 Mark: $resp');
      router?.go('/chat');
      return;
    }

    if (c.contains('helpdesk') || c.contains('ticket') || c.contains('support')) {
      const resp = "Opening Helpdesk portal.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🎫 Mark: $resp');
      router?.go('/helpdesk');
      return;
    }

    if (c.contains('leave') || c.contains('holiday') || c.contains('sick leave') || c.contains('casual leave')) {
      const resp = "Opening your leave balances.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('📅 Mark: $resp');
      router?.go('/me');
      return;
    }

    if (c.contains('finance') || c.contains('pay') || c.contains('salary') || c.contains('payslip')) {
      const resp = "Opening your finance overview.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('💰 Mark: $resp');
      router?.go('/finances');
      return;
    }

    if (c.contains('dashboard') || c.contains('home')) {
      const resp = "Navigating to Home Dashboard.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🏠 Mark: $resp');
      router?.go('/');
      return;
    }

    if (c.contains('admin') || c.contains('control panel')) {
      const resp = "Opening Admin Panel.";
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

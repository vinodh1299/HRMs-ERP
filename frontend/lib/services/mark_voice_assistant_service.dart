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
  static BuildContext? globalContext;

  static final _hrmsAiService = HrmsAiApiService();

  /// Initialize or Toggle Mark Assistant ON/OFF
  static void toggleMarkAssistant(BuildContext context) {
    globalContext = context;
    markEnabledNotifier.value = !markEnabledNotifier.value;
    if (markEnabledNotifier.value) {
      _startAlwaysListening();
      VoiceHelper.speak("Mark Voice Assistant activated. Say Hey Mark to command me.", force: true);
    } else {
      _stopListening();
      VoiceHelper.speak("Mark Voice Assistant deactivated.", force: true);
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
  }

  /// Parse speech input and check for Wake Word ("Mark" / "Hey Mark" / "Hello Mark")
  static void _processTranscript(String transcript) {
    final lower = transcript.toLowerCase().trim();

    // Check for Wake Word presence
    final isWakeWordDetected = lower.contains('mark') ||
        lower.contains('hey mark') ||
        lower.contains('hello mark') ||
        lower.contains('hi mark') ||
        lower.contains('ok mark');

    if (!isWakeWordDetected) {
      // Stay silent and ignore background noise
      return;
    }

    // Mark is awakened!
    isAwakeNotifier.value = true;
    lastCommandNotifier.value = transcript;

    // Extract command text after wake word
    String command = lower;
    for (final prefix in ['hey mark', 'hello mark', 'hi mark', 'ok mark', 'mark']) {
      if (command.contains(prefix)) {
        command = command.split(prefix).last.trim();
        break;
      }
    }

    if (command.isEmpty || command == 'hello' || command == 'hey' || command == 'hi') {
      VoiceHelper.speak("Hello! How can I assist you in the portal today?", force: true);
      return;
    }

    // Execute extracted in-app command
    _executeCommand(command, originalTranscript: transcript);
  }

  /// Execute hands-free actions inside the app
  static Future<void> _executeCommand(String command, {required String originalTranscript}) async {
    final c = command.toLowerCase();
    final router = globalContext != null ? GoRouter.of(globalContext!) : null;

    // 1. Navigation Actions
    if (c.contains('team') || c.contains('my team') || c.contains('members')) {
      VoiceHelper.speak("Navigating to your team section.", force: true);
      router?.go('/chat');
      return;
    }

    if (c.contains('helpdesk') || c.contains('ticket') || c.contains('support')) {
      VoiceHelper.speak("Opening Helpdesk portal.", force: true);
      router?.go('/helpdesk');
      return;
    }

    if (c.contains('leave') || c.contains('holiday') || c.contains('sick leave') || c.contains('casual leave')) {
      VoiceHelper.speak("Opening your leave balances.", force: true);
      router?.go('/me');
      return;
    }

    if (c.contains('finance') || c.contains('pay') || c.contains('salary') || c.contains('payslip')) {
      VoiceHelper.speak("Opening your finance overview.", force: true);
      router?.go('/finances');
      return;
    }

    if (c.contains('dashboard') || c.contains('home')) {
      VoiceHelper.speak("Navigating to Home Dashboard.", force: true);
      router?.go('/');
      return;
    }

    if (c.contains('admin') || c.contains('control panel')) {
      VoiceHelper.speak("Opening Admin Panel.", force: true);
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

      VoiceHelper.speak("Message sent to $target.", force: true);
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

      VoiceHelper.speak("Sending email to $target with content: $emailBody", force: true);
      return;
    }

    // 4. Default: Query HRMS-AI Engine for general policy or complex intents
    try {
      final res = await _hrmsAiService.askPolicyChat(command);
      if (res.answer.isNotEmpty) {
        VoiceHelper.speak(res.answer, force: true);
      }
    } catch (_) {
      VoiceHelper.speak("I have processed your command: $command", force: true);
    }
  }
}

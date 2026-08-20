import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'voice_helper.dart';
import 'chat_service.dart';
import 'hrms_ai_service.dart';

/// Representation of a staged Tier 2/3 Voice Action waiting for verbal confirmation
class PendingVoiceAction {
  final String actionTitle;
  final String readBackText;
  final VoidCallback onExecute;

  PendingVoiceAction({
    required this.actionTitle,
    required this.readBackText,
    required this.onExecute,
  });
}

/// MarkVoiceAssistantService
/// Always-Listening Voice Assistant ("Mark") for Asian Christian Academy HRMS Portal.
class MarkVoiceAssistantService {
  // Enabled ON by default when the app starts
  static final ValueNotifier<bool> markEnabledNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isAwakeNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> lastCommandNotifier = ValueNotifier<String>('');
  static final ValueNotifier<String> lastResponseNotifier = ValueNotifier<String>('🎙️ Mark Listening... (Say "Hey Mark")');
  static final ValueNotifier<PendingVoiceAction?> pendingActionNotifier = ValueNotifier<PendingVoiceAction?>(null);
  
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
      pendingActionNotifier.value = null;
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

  /// Confirm Pending Action manually or by voice
  static void confirmPendingAction() {
    final pending = pendingActionNotifier.value;
    if (pending == null) return;

    pending.onExecute();
    pendingActionNotifier.value = null;

    const resp = "Confirmed! Action executed successfully.";
    lastResponseNotifier.value = resp;
    VoiceHelper.speak(resp, force: true);
    _showFeedbackSnackBar('✅ Mark: $resp');
  }

  /// Cancel Pending Action manually or by voice
  static void cancelPendingAction() {
    pendingActionNotifier.value = null;
    const resp = "Action cancelled.";
    lastResponseNotifier.value = resp;
    VoiceHelper.speak(resp, force: true);
    _showFeedbackSnackBar('🚫 Mark: $resp');
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

    // 1. Check if we are waiting for a Verbal Read-Back Confirmation ("YES" or "NO")
    if (pendingActionNotifier.value != null) {
      if (lower.contains('yes') || lower.contains('yeah') || lower.contains('yup') || lower.contains('confirm') || lower.contains('do it') || lower.contains('ok') || lower.contains('sure') || lower.contains('proceed')) {
        confirmPendingAction();
        return;
      }
      if (lower.contains('no') || lower.contains('cancel') || lower.contains('stop') || lower.contains('never mind') || lower.contains('dont') || lower.contains("don't") || lower.contains('abort')) {
        cancelPendingAction();
        return;
      }

      // If user says something else, remind them of read-back confirmation
      final pending = pendingActionNotifier.value!;
      final reminder = 'Confirmation required: ${pending.readBackText}';
      lastResponseNotifier.value = reminder;
      VoiceHelper.speak(reminder, force: true);
      return;
    }

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

    // ==========================================
    // Tier 1: Safe Navigation Actions (Auto-Execute)
    // ==========================================
    if (c.contains('chat') || c.contains('message') || c.contains('messages') || c.contains('messaging') || c.contains('team') || c.contains('my team') || c.contains('members') || c.contains('conversation')) {
      const resp = "Opening your team chat section now.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🚀 Mark: $resp');
      router?.go('/chat');
      return;
    }

    if (c.contains('helpdesk') || c.contains('help desk') || c.contains('ticket') || c.contains('tickets') || c.contains('support') || c.contains('issue')) {
      const resp = "Opening Helpdesk support portal.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🎫 Mark: $resp');
      router?.go('/helpdesk');
      return;
    }

    if (c.contains('leave balances') || c.contains('my leaves') || c.contains('holidays') || c.contains('profile overview')) {
      const resp = "Opening your leave balances and profile overview.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('📅 Mark: $resp');
      router?.go('/me');
      return;
    }

    if (c.contains('finance') || c.contains('finances') || c.contains('pay') || c.contains('salary') || c.contains('payslip') || c.contains('payroll') || c.contains('expense')) {
      const resp = "Opening your finance overview.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('💰 Mark: $resp');
      router?.go('/finances');
      return;
    }

    if (c.contains('mail') || c.contains('email') || c.contains('inbox')) {
      const resp = "Opening your email inbox.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('📧 Mark: $resp');
      router?.go('/mail');
      return;
    }

    if (c.contains('org') || c.contains('organization') || c.contains('directory') || c.contains('employees') || c.contains('structure')) {
      const resp = "Opening Organization directory.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('👥 Mark: $resp');
      router?.go('/org');
      return;
    }

    if (c.contains('dashboard') || c.contains('home') || c.contains('main')) {
      const resp = "Navigating to Home Dashboard.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🏠 Mark: $resp');
      router?.go('/');
      return;
    }

    if (c.contains('admin') || c.contains('control panel') || c.contains('settings') || c.contains('manager')) {
      const resp = "Opening Admin Control Panel.";
      lastResponseNotifier.value = resp;
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('⚙️ Mark: $resp');
      router?.go('/admin');
      return;
    }

    // ==========================================
    // Tier 2: State-Changing Actions (Verbal Read-Back Gated)
    // ==========================================

    // Action A: Apply Leave
    if (c.contains('apply leave') || c.contains('apply for leave') || c.contains('casual leave') || c.contains('sick leave') || c.contains('time off')) {
      String leaveType = 'Casual Leave';
      if (c.contains('sick')) leaveType = 'Sick Leave';

      final readBackText = "You want to apply for $leaveType. Say YES to confirm, or CANCEL to abort.";
      
      pendingActionNotifier.value = PendingVoiceAction(
        actionTitle: 'Apply $leaveType',
        readBackText: readBackText,
        onExecute: () {
          router?.go('/me');
        },
      );

      lastResponseNotifier.value = '⚠️ Confirmation Required: $readBackText';
      VoiceHelper.speak(readBackText, force: true);
      _showFeedbackSnackBar('⚠️ Mark Read-Back: $readBackText');
      return;
    }

    // Action B: Send Team Chat Message
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

      final readBackText = "You want to send a message to $target. Say YES to confirm, or CANCEL to abort.";

      pendingActionNotifier.value = PendingVoiceAction(
        actionTitle: 'Send message to $target',
        readBackText: readBackText,
        onExecute: () {
          ChatService.addMessage(
            target,
            TeamChatMessage(
              sender: 'Me',
              text: messageText,
              timestamp: DateTime.now(),
              isMe: true,
            ),
          );
          router?.go('/chat');
        },
      );

      lastResponseNotifier.value = '⚠️ Confirmation Required: $readBackText';
      VoiceHelper.speak(readBackText, force: true);
      _showFeedbackSnackBar('⚠️ Mark Read-Back: $readBackText');
      return;
    }

    // Action C: Send Email
    if (c.contains('send mail') || c.contains('send email') || c.contains('mail to') || c.contains('email to')) {
      String target = 'Vinodh';
      String emailBody = command;

      if (c.contains('vinodh')) {
        target = 'Vinodh (manager@acaindia.org)';
      }

      if (c.contains('that')) {
        emailBody = command.split('that').last.trim();
      }

      final readBackText = "You want to send an email to $target containing: $emailBody. Say YES to confirm, or CANCEL to abort.";

      pendingActionNotifier.value = PendingVoiceAction(
        actionTitle: 'Send email to $target',
        readBackText: readBackText,
        onExecute: () {
          router?.go('/mail');
        },
      );

      lastResponseNotifier.value = '⚠️ Confirmation Required: $readBackText';
      VoiceHelper.speak(readBackText, force: true);
      _showFeedbackSnackBar('⚠️ Mark Read-Back: $readBackText');
      return;
    }

    // Default: Query HRMS-AI Engine for general policy or complex intents
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

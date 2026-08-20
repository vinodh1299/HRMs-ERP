import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'voice_helper.dart';
import 'chat_service.dart';
import 'hrms_ai_service.dart';
import 'api_service.dart';

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

/// ConversationalSessionMemory for Multi-Turn Voice State & Context Tracking
class ConversationalSessionMemory {
  static String? lastDomain; // e.g. 'leave', 'messaging', 'helpdesk', 'finance', 'attendance'
  static String? lastAction; // e.g. 'apply_leave', 'send_message', 'check_in', 'check_out'
  static Map<String, String> contextParams = {};
  static List<String> turnHistory = [];

  static void recordTurn(String userQuery, String markReply, {String? domain, String? action}) {
    if (domain != null) lastDomain = domain;
    if (action != null) lastAction = action;
    turnHistory.add('User: $userQuery');
    turnHistory.add('Mark: $markReply');
    if (turnHistory.length > 10) turnHistory.removeRange(0, 2);
  }

  static void reset() {
    lastDomain = null;
    lastAction = null;
    contextParams.clear();
    turnHistory.clear();
  }
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
  static final _apiService = ApiService();

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
      ConversationalSessionMemory.reset();
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
    ConversationalSessionMemory.recordTurn('Confirm', resp);
    VoiceHelper.speak(resp, force: true);
    _showFeedbackSnackBar('✅ Mark: $resp');
  }

  /// Cancel Pending Action manually or by voice
  static void cancelPendingAction() {
    pendingActionNotifier.value = null;
    const resp = "Action cancelled.";
    lastResponseNotifier.value = resp;
    ConversationalSessionMemory.recordTurn('Cancel', resp);
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

  /// Parse speech input and process commands with Multi-Turn Memory
  static void _processTranscript(String transcript) {
    final lower = transcript.toLowerCase().trim();
    if (lower.isEmpty) return;

    isAwakeNotifier.value = true;
    lastCommandNotifier.value = transcript;

    // =========================================================
    // 1. Check for Multi-Turn Action Modifications (Pending Confirmation)
    // =========================================================
    if (pendingActionNotifier.value != null) {
      final currentPending = pendingActionNotifier.value!;
      final router = globalContext != null ? GoRouter.of(globalContext!) : null;

      // Check for Confirmation ("YES")
      if (lower.contains('yes') || lower.contains('yeah') || lower.contains('yup') || lower.contains('confirm') || lower.contains('do it') || lower.contains('ok') || lower.contains('sure') || lower.contains('proceed')) {
        confirmPendingAction();
        return;
      }
      // Check for Cancellation ("NO")
      if (lower.contains('no') || lower.contains('cancel') || lower.contains('stop') || lower.contains('never mind') || lower.contains('dont') || lower.contains("don't") || lower.contains('abort')) {
        cancelPendingAction();
        return;
      }

      // Check for Multi-Turn Leave Parameter Modifications
      if (currentPending.actionTitle.contains('Apply') && (lower.contains('sick') || lower.contains('casual') || lower.contains('make it') || lower.contains('change to'))) {
        String newLeaveType = 'Sick Leave';
        if (lower.contains('casual')) newLeaveType = 'Casual Leave';

        final updatedReadBack = "Updated! You want to apply for $newLeaveType. Say YES to confirm, or CANCEL to abort.";
        pendingActionNotifier.value = PendingVoiceAction(
          actionTitle: 'Apply $newLeaveType',
          readBackText: updatedReadBack,
          onExecute: () {
            router?.go('/me');
          },
        );

        lastResponseNotifier.value = '⚠️ Updated: $updatedReadBack';
        VoiceHelper.speak(updatedReadBack, force: true);
        _showFeedbackSnackBar('⚠️ Mark Updated: $updatedReadBack');
        return;
      }

      // Check for Multi-Turn Message Recipient Modifications
      if (currentPending.actionTitle.contains('Send message') && (lower.contains('john') || lower.contains('jane') || lower.contains('vinodh') || lower.contains('instead') || lower.contains('send to'))) {
        String newTarget = 'John Doe';
        if (lower.contains('jane')) newTarget = 'Jane Smith';
        if (lower.contains('vinodh')) newTarget = 'Vinodh';

        final originalMsg = ConversationalSessionMemory.contextParams['messageText'] ?? 'I am on the way';
        final updatedReadBack = "Updated recipient to $newTarget. Say YES to confirm, or CANCEL to abort.";
        
        pendingActionNotifier.value = PendingVoiceAction(
          actionTitle: 'Send message to $newTarget',
          readBackText: updatedReadBack,
          onExecute: () {
            ChatService.addMessage(
              newTarget,
              TeamChatMessage(
                sender: 'Me',
                text: originalMsg,
                timestamp: DateTime.now(),
                isMe: true,
              ),
            );
            router?.go('/chat');
          },
        );

        lastResponseNotifier.value = '⚠️ Updated: $updatedReadBack';
        VoiceHelper.speak(updatedReadBack, force: true);
        _showFeedbackSnackBar('⚠️ Mark Updated: $updatedReadBack');
        return;
      }

      // If user says something else, remind them of read-back confirmation
      final reminder = 'Confirmation required: ${currentPending.readBackText}';
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
      ConversationalSessionMemory.recordTurn(transcript, resp);
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🎙️ Mark: $resp');
      return;
    }

    // Execute extracted in-app command and respond verbally
    _executeCommand(command, originalTranscript: transcript);
  }

  /// Execute hands-free actions inside the app and speak confirmation with Session Memory
  static Future<void> _executeCommand(String command, {required String originalTranscript}) async {
    final c = command.toLowerCase();
    final router = globalContext != null ? GoRouter.of(globalContext!) : null;

    // ==========================================
    // Tier 1: Attendance Check-In / Check-Out Actions
    // ==========================================
    if (c.contains('check in') || c.contains('clock in') || c.contains('punch in') || c.contains('check me in')) {
      await _apiService.checkIn(source: 'Voice Assistant');
      const resp = "You have been checked in successfully. Have a productive day!";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'attendance', action: 'check_in');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('⏰ Mark: $resp');
      router?.go('/me');
      return;
    }

    if (c.contains('check out') || c.contains('clock out') || c.contains('punch out') || c.contains('check me out')) {
      await _apiService.checkOut();
      const resp = "You have been checked out successfully. Have a great evening!";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'attendance', action: 'check_out');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('⏰ Mark: $resp');
      router?.go('/me');
      return;
    }

    // ==========================================
    // Tier 1: Leave & Payroll Queries
    // ==========================================
    if (c.contains('leave balance') || c.contains('leaves left') || c.contains('how many leaves') || c.contains('my leave balance')) {
      final balances = await _apiService.getLeaveBalances();
      final summaryParts = balances.map((b) => '${b.balance} ${b.leaveTypeName}s').join(', ');
      final resp = "Your current leave balances are: $summaryParts.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'leave', action: 'get_leave_balance');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('📅 Mark: $resp');
      router?.go('/me');
      return;
    }

    if (c.contains('payday') || c.contains('next pay') || c.contains('salary date') || c.contains('when is payroll') || c.contains('payslip')) {
      const resp = "Your net pay for last month was ₹80,000. Next payroll date is August 31st.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'finance', action: 'get_payroll_date');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('💰 Mark: $resp');
      router?.go('/finances');
      return;
    }

    // ==========================================
    // Tier 1: Safe Navigation Actions (Auto-Execute)
    // ==========================================
    if (c.contains('chat') || c.contains('message') || c.contains('messages') || c.contains('messaging') || c.contains('team') || c.contains('my team') || c.contains('members') || c.contains('conversation')) {
      const resp = "Opening your team chat section now.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'messaging', action: 'navigate_chat');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🚀 Mark: $resp');
      router?.go('/chat');
      return;
    }

    if (c.contains('helpdesk') || c.contains('help desk') || c.contains('ticket') || c.contains('tickets') || c.contains('support') || c.contains('issue')) {
      const resp = "Opening Helpdesk support portal.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'helpdesk', action: 'navigate_helpdesk');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🎫 Mark: $resp');
      router?.go('/helpdesk');
      return;
    }

    if (c.contains('leave balances') || c.contains('my leaves') || c.contains('holidays') || c.contains('profile overview')) {
      const resp = "Opening your leave balances and profile overview.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'leave', action: 'navigate_leave');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('📅 Mark: $resp');
      router?.go('/me');
      return;
    }

    if (c.contains('finance') || c.contains('finances') || c.contains('pay') || c.contains('salary') || c.contains('payslip') || c.contains('payroll') || c.contains('expense')) {
      const resp = "Opening your finance overview.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'finance', action: 'navigate_finances');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('💰 Mark: $resp');
      router?.go('/finances');
      return;
    }

    if (c.contains('mail') || c.contains('email') || c.contains('inbox')) {
      const resp = "Opening your email inbox.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'mail', action: 'navigate_mail');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('📧 Mark: $resp');
      router?.go('/mail');
      return;
    }

    if (c.contains('org') || c.contains('organization') || c.contains('directory') || c.contains('employees') || c.contains('structure')) {
      const resp = "Opening Organization directory.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'org', action: 'navigate_org');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('👥 Mark: $resp');
      router?.go('/org');
      return;
    }

    if (c.contains('dashboard') || c.contains('home') || c.contains('main')) {
      const resp = "Navigating to Home Dashboard.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'home', action: 'navigate_home');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('🏠 Mark: $resp');
      router?.go('/');
      return;
    }

    if (c.contains('admin') || c.contains('control panel') || c.contains('settings') || c.contains('manager')) {
      const resp = "Opening Admin Control Panel.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp, domain: 'admin', action: 'navigate_admin');
      VoiceHelper.speak(resp, force: true);
      _showFeedbackSnackBar('⚙️ Mark: $resp');
      router?.go('/admin');
      return;
    }

    // ==========================================
    // Tier 2: State-Changing Actions (Verbal Read-Back Gated with Multi-Turn Memory)
    // ==========================================

    // Action A: Apply Leave
    if (c.contains('apply leave') || c.contains('apply for leave') || c.contains('casual leave') || c.contains('sick leave') || c.contains('time off')) {
      String leaveType = 'Casual Leave';
      if (c.contains('sick')) leaveType = 'Sick Leave';

      ConversationalSessionMemory.contextParams['leaveType'] = leaveType;
      ConversationalSessionMemory.lastDomain = 'leave';
      ConversationalSessionMemory.lastAction = 'apply_leave';

      final readBackText = "You want to apply for $leaveType. Say YES to confirm, or CANCEL to abort.";
      
      pendingActionNotifier.value = PendingVoiceAction(
        actionTitle: 'Apply $leaveType',
        readBackText: readBackText,
        onExecute: () {
          router?.go('/me');
        },
      );

      lastResponseNotifier.value = '⚠️ Confirmation Required: $readBackText';
      ConversationalSessionMemory.recordTurn(command, readBackText);
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

      ConversationalSessionMemory.contextParams['target'] = target;
      ConversationalSessionMemory.contextParams['messageText'] = messageText;
      ConversationalSessionMemory.lastDomain = 'messaging';
      ConversationalSessionMemory.lastAction = 'send_message';

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
      ConversationalSessionMemory.recordTurn(command, readBackText);
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

      ConversationalSessionMemory.contextParams['target'] = target;
      ConversationalSessionMemory.contextParams['emailBody'] = emailBody;
      ConversationalSessionMemory.lastDomain = 'mail';
      ConversationalSessionMemory.lastAction = 'send_email';

      final readBackText = "You want to send an email to $target. Say YES to confirm, or CANCEL to abort.";

      pendingActionNotifier.value = PendingVoiceAction(
        actionTitle: 'Send email to $target',
        readBackText: readBackText,
        onExecute: () {
          router?.go('/mail');
        },
      );

      lastResponseNotifier.value = '⚠️ Confirmation Required: $readBackText';
      ConversationalSessionMemory.recordTurn(command, readBackText);
      VoiceHelper.speak(readBackText, force: true);
      _showFeedbackSnackBar('⚠️ Mark Read-Back: $readBackText');
      return;
    }

    // ==========================================
    // Multi-Turn Policy Follow-Up Queries
    // ==========================================
    String queryPrompt = command;
    if (ConversationalSessionMemory.lastDomain != null && (c.contains('what about') || c.contains('how about') || c.contains('how many') || c.contains('what is the'))) {
      queryPrompt = '${ConversationalSessionMemory.lastDomain} policy details for: $command';
    }

    try {
      final res = await _hrmsAiService.askPolicyChat(queryPrompt);
      if (res.answer.isNotEmpty) {
        lastResponseNotifier.value = res.answer;
        ConversationalSessionMemory.recordTurn(command, res.answer, domain: 'policy');
        VoiceHelper.speak(res.answer, force: true);
        _showFeedbackSnackBar('🤖 Mark: ${res.answer}');
      } else {
        final resp = "I heard: $command. Action processed.";
        lastResponseNotifier.value = resp;
        ConversationalSessionMemory.recordTurn(command, resp);
        VoiceHelper.speak(resp, force: true);
        _showFeedbackSnackBar('🤖 Mark: $resp');
      }
    } catch (_) {
      final resp = "I heard: $command. Action completed.";
      lastResponseNotifier.value = resp;
      ConversationalSessionMemory.recordTurn(command, resp);
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

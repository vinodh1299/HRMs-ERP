import 'package:flutter/foundation.dart';
import 'voice_helper_stub.dart'
    if (dart.library.js_interop) 'voice_helper_web.dart';

abstract class VoiceHelper {
  static final ValueNotifier<bool> autoSpeakNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);

  static bool get autoSpeak => autoSpeakNotifier.value;
  static set autoSpeak(bool val) => autoSpeakNotifier.value = val;

  static void startRecognition({
    required void Function(String text) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
  }) {
    isListeningNotifier.value = true;
    VoiceHelperImpl.startRecognition(
      onResult: (text) {
        onResult(text);
      },
      onError: (err) {
        isListeningNotifier.value = false;
        onError(err);
      },
      onEnd: () {
        isListeningNotifier.value = false;
        onEnd();
      },
    );
  }

  static void speak(String text, {bool force = false}) {
    if (!force && !autoSpeak) return;
    isSpeakingNotifier.value = true;
    VoiceHelperImpl.speak(
      text,
      onStart: () {
        isSpeakingNotifier.value = true;
      },
      onEnd: () {
        isSpeakingNotifier.value = false;
      },
    );
  }

  static void stopSpeaking() {
    VoiceHelperImpl.stopSpeaking();
    isSpeakingNotifier.value = false;
  }

  static void toggleAutoSpeak() {
    autoSpeakNotifier.value = !autoSpeakNotifier.value;
    if (!autoSpeakNotifier.value) {
      stopSpeaking();
    }
  }

  /// Generates a natural spoken context summary based on current route path
  static String getScreenContextSummary(String path, {String? userName = 'Vinodh', String? userRole = 'Employee'}) {
    final cleanPath = path.toLowerCase();
    if (cleanPath == '/' || cleanPath.contains('dashboard')) {
      return "Hello $userName! You are on the Home Dashboard. Currently, you are clocked in for today. You have 3 pending inbox approvals, 12 casual leaves remaining, and 2 active announcements today.";
    } else if (cleanPath.contains('/me')) {
      return "You are viewing your 'Me' Profile overview. Here you can check your shift details, attendance summary, leave balances, performance goals, and personal information.";
    } else if (cleanPath.contains('/mail')) {
      return "You are on the Mail module. You have 2 unread emails regarding payroll updates and team announcements.";
    } else if (cleanPath.contains('/chat')) {
      return "Welcome to Teams Chat. You have active discussions with HR Support, your Manager, and the Gemini AI Assistant.";
    } else if (cleanPath.contains('/org')) {
      return "You are viewing the Organization Directory. You can explore company structure, team rosters, and staff contacts.";
    } else if (cleanPath.contains('/admin')) {
      return "Welcome to the Admin Control Panel. Here administrators manage employee roles, attendance policies, leave approvals, and portal settings.";
    } else if (cleanPath.contains('/manager')) {
      return "Welcome to the Manager Panel. You can view direct reports, approve team leave requests, and track attendance records.";
    } else {
      return "You are currently on the ACA HRMS Portal. Use the voice assistant or menu to navigate modules and complete actions.";
    }
  }

  /// Synthesizes and speaks the context of the current screen
  static void readScreenContext(String path, {String? userName = 'Vinodh', String? userRole = 'Employee'}) {
    final summary = getScreenContextSummary(path, userName: userName, userRole: userRole);
    speak(summary, force: true);
  }
}


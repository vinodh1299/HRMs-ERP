class VoiceHelperImpl {
  static void startRecognition({
    required void Function(String text) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
    bool continuous = false,
  }) {
    onError("Voice Assistant not supported on this platform.");
    onEnd();
  }

  static void stopRecognition() {}

  static void speak(String text, {void Function()? onStart, void Function()? onEnd}) {
    onEnd?.call();
  }

  static void stopSpeaking() {}

  static bool isSpeaking() => false;
}

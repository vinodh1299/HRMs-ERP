class VoiceHelperImpl {
  static void startRecognition({
    required void Function(String text) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
  }) {
    onError("Voice Assistant not supported on this platform.");
    onEnd();
  }
}

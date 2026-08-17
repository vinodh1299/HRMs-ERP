import 'dart:js_interop';

@JS('startSpeechRecognition')
external void _jsStartSpeechRecognition(JSFunction onResult, JSFunction onError, JSFunction onEnd);

@JS('speakText')
external void _jsSpeakText(JSString text);

@JS('stopSpeaking')
external void _jsStopSpeaking();

class VoiceHelperImpl {
  static void startRecognition({
    required void Function(String text) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
  }) {
    try {
      _jsStartSpeechRecognition(
        ((JSString text) => onResult(text.toDart)).toJS,
        ((JSString error) => onError(error.toDart)).toJS,
        (() => onEnd()).toJS,
      );
    } catch (e) {
      onError("Speech recognition error: $e");
      onEnd();
    }
  }

  static void speak(String text) {
    try {
      _jsSpeakText(text.toJS);
    } catch (_) {}
  }

  static void stopSpeaking() {
    try {
      _jsStopSpeaking();
    } catch (_) {}
  }
}

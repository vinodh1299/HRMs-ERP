import 'dart:js_interop';

@JS('startSpeechRecognition')
external void _jsStartSpeechRecognition(JSFunction onResult, JSFunction onError, JSFunction onEnd);

@JS('speakText')
external void _jsSpeakText(JSString text, JSFunction? onStart, JSFunction? onEnd);

@JS('stopSpeaking')
external void _jsStopSpeaking();

@JS('isSpeaking')
external JSBoolean _jsIsSpeaking();

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

  static void speak(String text, {void Function()? onStart, void Function()? onEnd}) {
    try {
      final jsStart = onStart != null ? (() => onStart()).toJS : null;
      final jsEnd = onEnd != null ? (() => onEnd()).toJS : null;
      _jsSpeakText(text.toJS, jsStart, jsEnd);
    } catch (_) {
      onEnd?.call();
    }
  }

  static void stopSpeaking() {
    try {
      _jsStopSpeaking();
    } catch (_) {}
  }

  static bool isSpeaking() {
    try {
      return _jsIsSpeaking().toDart;
    } catch (_) {
      return false;
    }
  }
}


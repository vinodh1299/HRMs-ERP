import 'dart:js_interop';

@JS('startSpeechRecognition')
external void _jsStartSpeechRecognition(JSFunction onResult, JSFunction onError, JSFunction onEnd);

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
}

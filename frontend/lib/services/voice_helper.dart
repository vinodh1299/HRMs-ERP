import 'voice_helper_stub.dart'
    if (dart.library.js) 'voice_helper_web.dart';

abstract class VoiceHelper {
  static void startRecognition({
    required void Function(String text) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
  }) {
    VoiceHelperImpl.startRecognition(
      onResult: onResult,
      onError: onError,
      onEnd: onEnd,
    );
  }
}

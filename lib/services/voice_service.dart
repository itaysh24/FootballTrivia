import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  Future<void> init() async {
    _available = await _speech.initialize(
      onStatus: (status) => print("Speech status: $status"),
      onError: (err) => print("Speech error: $err"),
    );
  }

  Future<void> listen(Function(String) onResult) async {
    if (!_available) return;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 15), // max time per question
      pauseFor: const Duration(seconds: 3), // stops after 2s silence
      partialResults: false,
      localeId: "en_US", // adjust for language
    );
  }

  void stop() => _speech.stop();
}

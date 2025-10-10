// lib/pages/training/services/training_timer_service.dart
import 'dart:async';
import 'dart:ui';

class TrainingTimerService {
  Timer? _timer;
  int secondsLeft = 60;
  final VoidCallback? onTimeUp;
  final VoidCallback? onTimerUpdate;

  TrainingTimerService({this.onTimeUp, this.onTimerUpdate});

  void startTimer({int duration = 60}) {
    stop();
    secondsLeft = duration;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft > 0) {
        secondsLeft--;
        onTimerUpdate?.call();

        if (secondsLeft == 0) {
          onTimeUp?.call();
        }
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    if (_timer == null && secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (secondsLeft > 0) {
          secondsLeft--;
          onTimerUpdate?.call();

          if (secondsLeft == 0) {
            onTimeUp?.call();
          }
        }
      });
    }
  }

  String formatTime() {
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void dispose() {
    stop();
  }
}

import 'package:just_audio/just_audio.dart';

class NotificationSoundService {
  static const _assetPath = 'assets/sounds/notification.ogg';

  final AudioPlayer _player = AudioPlayer();

  Future<void> play() async {
    try {
      await _player.setAsset(_assetPath);
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {
      
    }
  }

  void dispose() {
    _player.dispose();
  }
}

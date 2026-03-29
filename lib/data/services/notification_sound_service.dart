import 'package:just_audio/just_audio.dart';
import 'package:voosu/data/data_sources/local/user_local_data_source.dart';

class NotificationSoundService {
  static const _assetPath = 'assets/sounds/notification.ogg';

  final AudioPlayer _player = AudioPlayer();
  final UserLocalDataSource _userLocal;

  NotificationSoundService(UserLocalDataSource userLocal) : _userLocal = userLocal;

  Future<void> play() async {
    if (!_userLocal.notificationSoundEnabled) {
      return;
    }
    try {
      await _player.setAsset(_assetPath);
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}

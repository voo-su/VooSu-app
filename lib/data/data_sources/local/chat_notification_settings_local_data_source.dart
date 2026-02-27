import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ChatNotificationSettingsLocalDataSource {
  Future<void> ensureLoaded();

  bool isMuted(int chatId);

  Future<void> setMuted(int chatId, bool muted);

  Set<int> get mutedChatIds;

  Stream<Set<int>> get mutedStream;
}

class ChatNotificationSettingsLocalDataSourceImpl implements ChatNotificationSettingsLocalDataSource {
  static const _key = 'voosu_chat_notifications_muted';

  SharedPreferences? _prefs;
  bool _loaded = false;
  Set<int> _mutedIds = {};
  final StreamController<Set<int>> _streamController = StreamController<Set<int>>.broadcast();

  @override
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _prefs ??= await SharedPreferences.getInstance();
    final list = _prefs!.getStringList(_key);
    _mutedIds = list != null ? list.map((s) => int.tryParse(s) ?? 0).where((i) => i != 0).toSet() : {};
    _loaded = true;
    _streamController.add(Set.from(_mutedIds));
  }

  @override
  bool isMuted(int chatId) {
    if (!_loaded) return false;
    return _mutedIds.contains(chatId);
  }

  @override
  Future<void> setMuted(int chatId, bool muted) async {
    await ensureLoaded();
    if (muted) {
      _mutedIds.add(chatId);
    } else {
      _mutedIds.remove(chatId);
    }
    await _prefs!.setStringList(_key, _mutedIds.map((i) => i.toString()).toList());
    _streamController.add(Set.from(_mutedIds));
  }

  @override
  Set<int> get mutedChatIds => Set.from(_mutedIds);

  @override
  Stream<Set<int>> get mutedStream => _streamController.stream;
}

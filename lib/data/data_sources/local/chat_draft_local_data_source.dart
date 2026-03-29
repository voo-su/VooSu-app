import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voosu/domain/entities/chat.dart';

class ChatDraftLocalDataSource extends ChangeNotifier {
  static const _prefix = 'voosu.chatDraft.';

  final Map<String, String> _cache = {};
  SharedPreferences? _prefs;
  Future<void>? _hydrateFuture;

  Future<void> hydrate() {
    _hydrateFuture ??= _hydrateInternal();
    return _hydrateFuture!;
  }

  Future<void> _hydrateInternal() async {
    _prefs = await SharedPreferences.getInstance();
    for (final k in _prefs!.getKeys()) {
      if (k.startsWith(_prefix)) {
        final short = k.substring(_prefix.length);
        final v = _prefs!.getString(k);
        if (v != null && v.isNotEmpty) {
          _cache[short] = v;
        }
      }
    }
    notifyListeners();
  }

  static String storageKey(Chat chat) => chat.isGroup ? 'g${chat.peerGroupId}' : 'u${chat.peerUserId}';

  String? peekForChat(Chat chat) {
    final v = _cache[storageKey(chat)];
    if (v == null || v.isEmpty) {
      return null;
    }
    return v;
  }

  Future<void> save(Chat chat, String text) async {
    await hydrate();
    final key = storageKey(chat);
    if (text.trim().isEmpty) {
      await _removeKey(key);
      return;
    }
    final prev = _cache[key];
    if (prev == text) {
      return;
    }
    _cache[key] = text;
    await _prefs!.setString('$_prefix$key', text);
    notifyListeners();
  }

  Future<void> removeForChat(Chat chat) async {
    await hydrate();
    await _removeKey(storageKey(chat));
  }

  Future<void> removeForGroupId(int peerGroupId) async {
    await hydrate();
    await _removeKey('g$peerGroupId');
  }

  Future<void> _removeKey(String key) async {
    final had = _cache.remove(key) != null;
    final inPrefs = _prefs?.containsKey('$_prefix$key') ?? false;
    if (inPrefs) {
      await _prefs!.remove('$_prefix$key');
    }
    if (had || inPrefs) {
      notifyListeners();
    }
  }
}

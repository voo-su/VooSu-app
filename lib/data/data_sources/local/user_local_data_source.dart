import 'package:voosu/data/db/app_database.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class UserLocalDataSource {
  String? get accessToken;
  String? get refreshToken;
  User? get user;
  bool get hasToken;

  void saveTokens(String accessToken, String refreshToken);
  void saveUser(User user);
  void clearTokens();

  Future<void> init();

  Future<void> setSyncState(int pts, int date);

  Future<Map<String, dynamic>> getSyncState();

  Future<void> clearSyncState();

  Future<void> clearAuthData();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  static const _keyAccessToken = 'voosu_access_token';
  static const _keyRefreshToken = 'voosu_refresh_token';
  static const _keyUserId = 'voosu_user_id';
  static const _keyUserUsername = 'voosu_user_username';
  static const _keyUserName = 'voosu_user_name';
  static const _keyUserSurname = 'voosu_user_surname';
  static const _keyUserAvatarFileId = 'voosu_user_avatar_file_id';
  static const _syncPtsKey = 'voosu_pts_key';
  static const _syncDateKey = 'voosu_date_key';

  SharedPreferences? _prefs;
  String? _accessToken;
  String? _refreshToken;
  User? _user;
  final AppDatabase? _db;

  UserLocalDataSourceImpl({AppDatabase? db}) : _db = db;

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  User? get user => _user;

  @override
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  @override
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _accessToken = _prefs!.getString(_keyAccessToken);
    _refreshToken = _prefs!.getString(_keyRefreshToken);
    final id = _prefs!.getInt(_keyUserId);
    final username = _prefs!.getString(_keyUserUsername);
    final name = _prefs!.getString(_keyUserName);
    final surname = _prefs!.getString(_keyUserSurname) ?? '';
    final avatarFileId = _prefs!.getInt(_keyUserAvatarFileId);

    if (id != null && username != null && name != null) {
      _user = User(
        id: id,
        username: username,
        name: name,
        surname: surname,
        avatarFileId: avatarFileId,
      );
    } else {
      _user = null;
    }
  }

  @override
  void saveTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _prefs?.setString(_keyAccessToken, accessToken);
    _prefs?.setString(_keyRefreshToken, refreshToken);
  }

  @override
  void saveUser(User user) {
    _user = user;
    _prefs?.setInt(_keyUserId, user.id);
    _prefs?.setString(_keyUserUsername, user.username);
    _prefs?.setString(_keyUserName, user.name);
    _prefs?.setString(_keyUserSurname, user.surname);
    if (user.avatarFileId != null) {
      _prefs?.setInt(_keyUserAvatarFileId, user.avatarFileId!);
    } else {
      _prefs?.remove(_keyUserAvatarFileId);
    }
  }

  @override
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _prefs?.remove(_keyAccessToken);
    _prefs?.remove(_keyRefreshToken);
    _prefs?.remove(_keyUserId);
    _prefs?.remove(_keyUserUsername);
    _prefs?.remove(_keyUserName);
    _prefs?.remove(_keyUserSurname);
    _prefs?.remove(_keyUserAvatarFileId);
  }

  @override
  Future<void> setSyncState(int pts, int date) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_syncPtsKey, pts);
    await _prefs!.setInt(_syncDateKey, date);
  }

  @override
  Future<Map<String, dynamic>> getSyncState() async {
    _prefs ??= await SharedPreferences.getInstance();
    final pts = _prefs!.getInt(_syncPtsKey);
    final date = _prefs!.getInt(_syncDateKey);
    return {
      'pts': pts ?? 0,
      'date': date ?? 0,
    };
  }

  @override
  Future<void> clearSyncState() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_syncPtsKey);
    await _prefs!.remove(_syncDateKey);
  }

  @override
  Future<void> clearAuthData() async {
    clearTokens();
    await _db?.clearPendingData();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.clear();
  }
}

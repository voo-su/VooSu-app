import 'package:flutter/material.dart';
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

  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  Future<void> init();

  Future<void> setSyncState(int pts, int date);

  Future<Map<String, dynamic>> getSyncState();

  Future<void> clearSyncState();

  Future<void> clearAuthData();

  bool get notificationSoundEnabled;

  Future<void> setNotificationSoundEnabled(bool enabled);
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  static const _keyAccessToken = 'voosu_access_token';
  static const _keyRefreshToken = 'voosu_refresh_token';
  static const _keyUserId = 'voosu_user_id';
  static const _keyUserUsername = 'voosu_user_username';
  static const _keyUserName = 'voosu_user_name';
  static const _keyUserSurname = 'voosu_user_surname';
  static const _keyUserGender = 'voosu_user_gender';
  static const _keyUserBirthday = 'voosu_user_birthday';
  static const _keyUserAbout = 'voosu_user_about';
  static const _keyUserAvatarFileId = 'voosu_user_avatar_file_id';
  static const _keyUserMessagePrivacy = 'voosu_user_message_privacy';
  static const _keyThemeMode = 'voosu_theme_mode';
  static const _keyNotificationSoundEnabled = 'voosu_notification_sound_enabled';
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
    final gender = _prefs!.getInt(_keyUserGender) ?? 0;
    final birthday = _prefs!.getString(_keyUserBirthday) ?? '';
    final about = _prefs!.getString(_keyUserAbout) ?? '';
    final avatarFileId = _prefs!.getInt(_keyUserAvatarFileId);
    final messagePrivacy = _prefs!.getInt(_keyUserMessagePrivacy) ?? 0;

    if (id != null && username != null && name != null) {
      _user = User(
        id: id,
        username: username,
        name: name,
        surname: surname,
        gender: gender,
        birthday: birthday,
        about: about,
        avatarFileId: avatarFileId,
        messagePrivacy: messagePrivacy,
      );
    } else {
      _user = null;
    }
    await _db?.initSyncStateIfNeeded();
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
    _prefs?.setInt(_keyUserGender, user.gender);
    _prefs?.setString(_keyUserBirthday, user.birthday);
    _prefs?.setString(_keyUserAbout, user.about);
    if (user.avatarFileId != null) {
      _prefs?.setInt(_keyUserAvatarFileId, user.avatarFileId!);
    } else {
      _prefs?.remove(_keyUserAvatarFileId);
    }
    _prefs?.setInt(_keyUserMessagePrivacy, user.messagePrivacy);
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
    _prefs?.remove(_keyUserGender);
    _prefs?.remove(_keyUserBirthday);
    _prefs?.remove(_keyUserAbout);
    _prefs?.remove(_keyUserAvatarFileId);
    _prefs?.remove(_keyUserMessagePrivacy);
  }

  @override
  ThemeMode getThemeMode() {
    final index = _prefs?.getInt(_keyThemeMode);
    if (index == null) {
      return ThemeMode.light;
    }

    if (index < 0 || index >= ThemeMode.values.length) {
      return ThemeMode.light;
    }

    return ThemeMode.values[index];
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs?.setInt(_keyThemeMode, mode.index);
  }

  @override
  Future<void> setSyncState(int pts, int date) async {
    await _db?.setSyncState(pts, date);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_syncPtsKey, pts);
    await _prefs!.setInt(_syncDateKey, date);
  }

  @override
  Future<Map<String, dynamic>> getSyncState() async {
    final row = await _db?.getSyncStateRow();
    if (row != null) {
      return {
        'pts': row.pts,
        'date': row.date,
      };
    }

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
    await _db?.resetSyncState();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_syncPtsKey);
    await _prefs!.remove(_syncDateKey);
  }

  @override
  Future<void> clearAuthData() async {
    clearTokens();
    await _db?.clearCache();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.clear();
  }

  @override
  bool get notificationSoundEnabled =>
      _prefs?.getBool(_keyNotificationSoundEnabled) ?? true;

  @override
  Future<void> setNotificationSoundEnabled(bool enabled) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyNotificationSoundEnabled, enabled);
  }
}

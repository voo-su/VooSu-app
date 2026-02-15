import 'package:shared_preferences/shared_preferences.dart';
import 'package:voosu/core/app_server_constants.dart';

class ServerConfig {
  static const _keyAddress = 'voosu_server_address';
  static const _keyHost = 'voosu_server_host';
  static const _keyPort = 'voosu_server_port';

  String _address = '';
  SharedPreferences? _prefs;

  String get address => _address;

  String get host {
    final parts = _address.split(':');
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  int get port {
    final parts = _address.split(':');
    if (parts.length < 2) {
      return AppServerConstants.grpcPort;
    }

    return int.tryParse(parts[1].trim()) ?? AppServerConstants.grpcPort;
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _address = AppServerConstants.grpcAddress;
    await _prefs?.remove(_keyAddress);
    await _prefs?.remove(_keyHost);
    await _prefs?.remove(_keyPort);
  }

  Future<void> setServerAddress(String address) async {
    final trimmed = address.trim();
    if (_address == trimmed) {
      return;
    }

    _address = trimmed;
    await _prefs?.setString(_keyAddress, trimmed);
  }
}

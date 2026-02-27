import 'dart:async';

class UserOnlineStatusService {
  final Map<int, bool> _status = {};
  final StreamController<Map<int, bool>> _controller = StreamController<Map<int, bool>>.broadcast();

  Stream<Map<int, bool>> get statusStream => _controller.stream;

  Map<int, bool> get statusMap => Map.from(_status);

  bool? isOnline(int userId) => _status[userId];

  void setUserOnline(int userId, bool online) {
    if (_status[userId] == online) return;
    _status[userId] = online;
    _controller.add(statusMap);
  }

  void dispose() {
    _controller.close();
  }
}

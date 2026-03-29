import 'package:flutter/foundation.dart';

enum UploadQueuePhase {
  waiting,
  uploading,
  complete,
  error,
}

@immutable
class UploadQueueItem {
  const UploadQueueItem({
    required this.id,
    required this.filename,
    required this.totalBytes,
    required this.progress,
    required this.phase,
    this.errorMessage,
  });

  final String id;
  final String filename;
  final int? totalBytes;
  final double progress;
  final UploadQueuePhase phase;
  final String? errorMessage;

  UploadQueueItem copyWith({
    String? id,
    String? filename,
    int? totalBytes,
    double? progress,
    UploadQueuePhase? phase,
    String? errorMessage,
  }) {
    return UploadQueueItem(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      totalBytes: totalBytes ?? this.totalBytes,
      progress: progress ?? this.progress,
      phase: phase ?? this.phase,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class UploadQueueService extends ChangeNotifier {
  static const int _maxItems = 40;
  int _seq = 0;

  bool panelVisible = false;
  final List<UploadQueueItem> _items = [];

  List<UploadQueueItem> get items => List.unmodifiable(_items);

  bool get hasActiveWork =>
      _items.any(
        (e) =>
            e.phase == UploadQueuePhase.waiting ||
            e.phase == UploadQueuePhase.uploading,
      );

  String begin({required String filename, int? totalBytes}) {
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_seq++}';
    _items.insert(
      0,
      UploadQueueItem(
        id: id,
        filename: filename,
        totalBytes: totalBytes,
        progress: 0,
        phase: UploadQueuePhase.waiting,
      ),
    );
    while (_items.length > _maxItems) {
      _items.removeLast();
    }
    panelVisible = true;
    notifyListeners();
    return id;
  }

  void reportProgress(String id, int sentBytes, int? totalBytes) {
    final i = _indexOf(id);
    if (i < 0) return;
    final t = totalBytes ?? _items[i].totalBytes;
    double p = 0;
    if (t != null && t > 0) {
      p = (sentBytes / t).clamp(0.0, 1.0);
    }
    _items[i] = _items[i].copyWith(
      phase: UploadQueuePhase.uploading,
      progress: p,
    );
    notifyListeners();
  }

  void complete(String id) {
    final i = _indexOf(id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(
      phase: UploadQueuePhase.complete,
      progress: 1,
    );
    notifyListeners();
  }

  void fail(String id, String message) {
    final i = _indexOf(id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(
      phase: UploadQueuePhase.error,
      errorMessage: message,
    );
    notifyListeners();
  }

  void closePanel() {
    panelVisible = false;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    panelVisible = false;
    notifyListeners();
  }

  int _indexOf(String id) {
    for (var j = 0; j < _items.length; j++) {
      if (_items[j].id == id) return j;
    }
    return -1;
  }
}

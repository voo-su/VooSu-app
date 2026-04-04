String storageFileIdFromJson(dynamic value) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value.trim();
  }

  if (value is num) {
    return value.toInt().toString();
  }

  return '';
}

bool looksLikeStorageFileId(String s) {
  final t = s.trim();
  if (t.isEmpty) {
    return false;
  }

  return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(t);
}

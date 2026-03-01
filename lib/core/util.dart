import 'package:flutter/material.dart';
import 'package:voosu/domain/entities/user.dart';

String participantsSubtitle(int count, {String? emptyLabel}) {
  if (count <= 0) {
    return emptyLabel ?? 'групповой чат';
  }

  if (count == 1) {
    return '1 участник';
  }

  if (count >= 2 && count <= 4) {
    return '$count участника';
  }

  return '$count участников';
}

String userDisplayNameForId(List<User>? members, int userId) {
  if (members == null) {
    return 'ID: $userId';
  }

  try {
    final user = members.firstWhere((u) => u.id == userId);
    return user.username.isNotEmpty || user.name.isNotEmpty || user.surname.isNotEmpty
      ? user.displayName
      : 'ID: $userId';
  } catch (_) {
    return 'ID: $userId';
  }
}

bool isBlank(String? value) => value == null || value.isEmpty;

bool isBlankTrimmed(String? value) => value == null || value.trim().isEmpty;

Color labelColorFromHex(String hex) {
  if (hex.isEmpty) {
    return Colors.grey;
  }

  var h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length == 6) {
    h = 'FF$h';
  }

  final v = int.tryParse(h, radix: 16);
  return v != null ? Color(v) : Colors.grey;
}

import 'package:flutter/material.dart';

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

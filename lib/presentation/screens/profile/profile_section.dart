import 'package:flutter/material.dart';

enum ProfileSection {
  overview,
  security,
  notifications,
  devices,
  appearance,
}

extension ProfileSectionX on ProfileSection {
  String get label {
    switch (this) {
      case ProfileSection.overview:
        return 'Профиль';
      case ProfileSection.security:
        return 'Безопасность';
      case ProfileSection.notifications:
        return 'Уведомления';
      case ProfileSection.devices:
        return 'Устройства';
      case ProfileSection.appearance:
        return 'Оформление';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileSection.overview:
        return Icons.person_outline_rounded;
      case ProfileSection.security:
        return Icons.lock_outline_rounded;
      case ProfileSection.notifications:
        return Icons.notifications_outlined;
      case ProfileSection.devices:
        return Icons.devices_rounded;
      case ProfileSection.appearance:
        return Icons.palette_outlined;
    }
  }
}

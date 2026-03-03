import 'package:flutter/material.dart';
import 'package:voosu/presentation/screens/profile/profile_section.dart';
import 'package:voosu/presentation/screens/profile/widgets/profile_devices_widget.dart';
import 'package:voosu/presentation/screens/profile/widgets/profile_overview_widget.dart';
import 'package:voosu/presentation/screens/profile/widgets/profile_security_widget.dart';

class ProfileSectionScreen extends StatelessWidget {
  const ProfileSectionScreen({super.key, required this.section});

  final ProfileSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(section.label)),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (section) {
      case ProfileSection.overview:
        return const ProfileOverviewWidget();
      case ProfileSection.devices:
        return const ProfileDevicesWidget();
      case ProfileSection.security:
        return const ProfileSecurityWidget();
    }
  }
}

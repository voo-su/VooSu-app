import 'package:flutter/material.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/data/data_sources/local/user_local_data_source.dart';

class ProfileNotificationsWidget extends StatefulWidget {
  const ProfileNotificationsWidget({super.key, this.scrollable = true});

  final bool scrollable;

  @override
  State<ProfileNotificationsWidget> createState() =>
      _ProfileNotificationsWidgetState();
}

class _ProfileNotificationsWidgetState
    extends State<ProfileNotificationsWidget> {
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = di.sl<UserLocalDataSource>().notificationSoundEnabled;
  }

  Future<void> _setSound(bool value) async {
    await di.sl<UserLocalDataSource>().setNotificationSoundEnabled(value);
    if (mounted) {
      setState(() => _soundEnabled = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: Text(
            'Уведомления',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Звуковые уведомления'),
              subtitle: Text(
                'Воспроизводить звук при новом сообщении',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: _soundEnabled,
              onChanged: (v) => _setSound(v),
            ),
          ),
        ),
      ],
    );

    if (widget.scrollable) {
      return SingleChildScrollView(child: body);
    }
    return body;
  }
}

import 'package:flutter/material.dart';
import 'package:voosu/presentation/screens/profile/change_email_screen.dart';
import 'package:voosu/presentation/screens/profile/change_username_screen.dart';

class ProfileSecurityWidget extends StatelessWidget {
  const ProfileSecurityWidget({super.key, this.scrollable = true});

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              Icons.alternate_email_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Смена логина'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ChangeUsernameScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.mail_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Смена почты'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ChangeEmailScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );

    final padded = Padding(padding: const EdgeInsets.all(24), child: column);
    if (scrollable) {
      return SingleChildScrollView(child: padded);
    }
    return padded;
  }
}

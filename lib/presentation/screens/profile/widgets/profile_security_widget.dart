import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/usecases/account/get_confidentiality_settings_usecase.dart';
import 'package:voosu/domain/usecases/account/update_confidentiality_settings_usecase.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_event.dart';
import 'package:voosu/presentation/screens/profile/change_email_screen.dart';
import 'package:voosu/presentation/screens/profile/change_username_screen.dart';

class ProfileSecurityWidget extends StatefulWidget {
  const ProfileSecurityWidget({super.key, this.scrollable = true});

  final bool scrollable;

  @override
  State<ProfileSecurityWidget> createState() => _ProfileSecurityWidgetState();
}

class _ProfileSecurityWidgetState extends State<ProfileSecurityWidget> {
  int? _messagePrivacy;
  bool _loadingPrivacy = true;
  bool _savingPrivacy = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    setState(() {
      _loadingPrivacy = true;
    });
    try {
      final v = await di.sl<GetConfidentialitySettingsUseCase>()();
      if (mounted) {
        setState(() {
          _messagePrivacy = v;
          _loadingPrivacy = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      final cached = context.read<AuthBloc>().state.user?.messagePrivacy ?? 0;
      setState(() {
        _messagePrivacy = cached;
        _loadingPrivacy = false;
      });
    }
  }

  Future<void> _onPrivacySelected(int value) async {
    if (_savingPrivacy || value == _messagePrivacy) return;
    setState(() => _savingPrivacy = true);
    try {
      await di.sl<UpdateConfidentialitySettingsUseCase>()(value);
      if (!mounted) return;
      setState(() {
        _messagePrivacy = value;
        _savingPrivacy = false;
      });
      context.read<AuthBloc>().add(AuthMessagePrivacyUpdated(value));
    } catch (e) {
      if (mounted) {
        setState(() => _savingPrivacy = false);
        final msg = e is Failure
            ? e.message
            : e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final privacyCard = Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Кто может писать в личные сообщения',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Как на сайте: все пользователи или только из списка контактов.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingPrivacy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('Все'),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('Только контакты'),
                  ),
                ],
                selected: {_messagePrivacy ?? 0},
                showSelectedIcon: false,
                onSelectionChanged: (s) => _onPrivacySelected(s.first),
              ),
          ],
        ),
      ),
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        privacyCard,
        const SizedBox(height: 12),
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
    if (widget.scrollable) {
      return SingleChildScrollView(child: padded);
    }
    return padded;
  }
}

import 'package:flutter/material.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/presentation/widgets/avatar_from_file_id.dart';

class ChatListAvatar extends StatelessWidget {
  final String title;
  final double size;
  final int? avatarFileId;

  const ChatListAvatar({
    super.key,
    required this.title,
    this.size = 48,
    this.avatarFileId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return avatarFileId != null && avatarFileId != 0
        ? AvatarFromFileId(
            fileId: avatarFileId,
            letter: letter,
            size: size,
            accountRepository: di.sl<AccountRepository>(),
          )
        : CircleAvatar(
            radius: size / 2,
            backgroundColor: theme.primaryContainer,
            child: Text(
              letter,
              style: TextStyle(
                color: theme.onPrimaryContainer,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
  }
}

import 'package:flutter/material.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/presentation/widgets/avatar_from_file_id.dart';

class ChatListAvatar extends StatelessWidget {
  final String title;
  final bool? isOnline;
  final double size;
  final String? photoId;

  const ChatListAvatar({
    super.key,
    required this.title,
    this.isOnline,
    this.size = 48,
    this.photoId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        photoId != null && photoId!.trim().isNotEmpty
        ? AvatarFromFileId(
          fileId: photoId,
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
        ),
        if (isOnline != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline!
                  ? const Color(0xFF4CAF50)
                  : theme.outline.withValues(alpha: 0.5),
                border: Border.all(color: theme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

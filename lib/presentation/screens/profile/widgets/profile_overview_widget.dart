import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/domain/usecases/chat/upload_chat_file_usecase.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/widgets/avatar_from_file_id.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_event.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_state.dart';

class ProfileOverviewWidget extends StatelessWidget {
  const ProfileOverviewWidget({super.key, this.scrollable = true});

  final bool scrollable;

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.single.path;
    if (path == null) {
      return;
    }

    final bytes = await File(path).readAsBytes();
    final filename = result.files.single.name;
    if (filename.isEmpty) {
      return;
    }

    try {
      final fileId = await di.sl<UploadChatFileUseCase>().call(
        filename: filename,
        chunkStream: Stream.fromIterable([bytes]),
        totalBytes: bytes.length,
      );
      final repo = di.sl<AccountRepository>();
      final uploadResult = await repo.uploadProfilePhoto(fileId);
      if (context.mounted) {
        context.read<AuthBloc>().add(
          AuthProfilePhotoUpdated(uploadResult.avatarFileId),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить фото')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final displayName = user != null
            ? ('${user.name} ${user.surname}'.trim().isNotEmpty
                  ? '${user.name} ${user.surname}'.trim()
                  : 'Пользователь')
            : 'Пользователь';
        final username = user != null ? '@${user.username}' : '';
        final letter = displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : '?';
        final accountRepo = di.sl<AccountRepository>();

        final content = Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _pickAndUploadPhoto(context),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AvatarFromFileId(
                              fileId: user?.avatarFileId,
                              letter: letter,
                              size: 80,
                              accountRepository: accountRepo,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (username.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                username,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        if (scrollable) {
          return SingleChildScrollView(child: content);
        }
        return content;
      },
    );
  }
}

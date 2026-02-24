import 'package:desktop_drop/desktop_drop.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/attachment_type_helper.dart';
import 'package:voosu/core/client_local_id.dart';
import 'package:voosu/core/file_stream.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';

const int _chatAttachmentMaxBytes = 10 * 1024 * 1024;
const int _largeFileThresholdBytes = 5 * 1024 * 1024;

typedef OnSendMessage = void Function(
  String text,
  {List<AttachmentUpload>? attachments}
);

typedef OnUploadFile = Future<int?> Function(
  String filename,
  Stream<List<int>> chunkStream,
  int totalBytes, [
  void Function(int sentBytes, int? totalBytes)? onProgress,
]);

typedef OnUploadLargeFile = Future<int?> Function(
  String path,
  String filename,
  int size, [
  void Function(int sentBytes, int? totalBytes)? onProgress,
]);

typedef OnSendWithLargeFiles = Future<void> Function(
  String text,
  List<AttachmentUpload> attachments,
);

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final OnSendMessage onSendMessage;
  final bool isEnabled;
  final bool isSending;
  final OnUploadFile? uploadFile;
  final OnUploadLargeFile? uploadLargeFile;
  final OnSendWithLargeFiles? onSendWithLargeFiles;
  final String? hintText;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.isEnabled,
    required this.isSending,
    this.uploadFile,
    this.uploadLargeFile,
    this.onSendWithLargeFiles,
    this.hintText,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final List<PlatformFile> _selectedFiles = [];
  bool _isDraggingFile = false;
  bool _showEmojiPicker = false;

  void _toggleEmojiPicker() {
    if (!widget.isEnabled) return;
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _send() async {
    final text = widget.controller.text.trim();
    final hasFiles = _selectedFiles.isNotEmpty;
    if (text.isEmpty && !hasFiles) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);

    if (hasFiles) {
      for (final f in _selectedFiles) {
        if (f.path == null && (f.bytes == null || f.bytes!.isEmpty)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось прочитать файл')),
            );
          }

          return;
        }

        if (f.path != null &&
            f.size > _largeFileThresholdBytes &&
            widget.uploadLargeFile == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Большие файлы не поддерживаются')),
            );
          }

          return;
        }
      }
    }

    final List<({String filename, List<int> bytes})> smallFilesToUpload = [];
    final List<LargeFileRef> largeFileRefs = [];

    if (hasFiles) {
      for (final f in _selectedFiles) {
        if (f.path != null &&
            f.size > _largeFileThresholdBytes &&
            widget.uploadLargeFile != null) {
          largeFileRefs.add(
            LargeFileRef(path: f.path!, filename: f.name, size: f.size),
          );
        } else if (f.bytes != null && f.bytes!.isNotEmpty) {
          if (f.bytes!.length <= _chatAttachmentMaxBytes) {
            smallFilesToUpload.add((filename: f.name, bytes: f.bytes!));
          }
        } else if (f.path != null) {
          try {
            final bytes = await readFileBytes(f.path!);
            if (bytes.length <= _chatAttachmentMaxBytes) {
              smallFilesToUpload.add((filename: f.name, bytes: bytes));
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Файл слишком большой: ${f.name}')),
              );
              return;
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Не удалось прочитать файл: ${f.name}')),
              );
            }

            return;
          }
        }
      }
    }

    if (smallFilesToUpload.isNotEmpty && widget.uploadFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Загрузка файлов недоступна')),
        );
      }

      return;
    }

    final List<AttachmentUpload> uploadedAttachments = [];
    if (smallFilesToUpload.isNotEmpty && widget.uploadFile != null) {
      for (final entry in smallFilesToUpload) {
        try {
          final fileId = await widget.uploadFile!(
            entry.filename,
            Stream.fromIterable([entry.bytes]),
            entry.bytes.length,
          );
          if (fileId != null && fileId != 0) {
            uploadedAttachments.add(
              AttachmentUpload(filename: entry.filename, fileId: fileId),
            );
          } else {
            if (mounted && messenger != null) {
              messenger.showSnackBar(
                SnackBar(content: Text('Ошибка загрузки: ${entry.filename}')),
              );
            }
            return;
          }
        } catch (_) {
          if (mounted && messenger != null) {
            messenger.showSnackBar(
              SnackBar(content: Text('Ошибка загрузки: ${entry.filename}')),
            );
          }
          return;
        }
      }
    }

    if (text.isEmpty && uploadedAttachments.isEmpty && largeFileRefs.isEmpty) {
      return;
    }

    if (largeFileRefs.isNotEmpty && widget.uploadLargeFile != null) {
      if (widget.onSendWithLargeFiles != null) {
        final allAttachments = [...uploadedAttachments];
        for (final ref in largeFileRefs) {
          try {
            final fileId = await widget.uploadLargeFile!(
              ref.path,
              ref.filename,
              ref.size,
            );
            if (fileId != null && fileId != 0) {
              allAttachments.add(
                AttachmentUpload(filename: ref.filename, fileId: fileId),
              );
            } else {
              if (mounted && messenger != null) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Ошибка загрузки: ${ref.filename}')),
                );
              }
              return;
            }
          } catch (_) {
            if (mounted && messenger != null) {
              messenger.showSnackBar(
                SnackBar(content: Text('Ошибка загрузки: ${ref.filename}')),
              );
            }
            return;
          }
        }
        final body = text.isEmpty ? '[файлы]' : text;
        await widget.onSendWithLargeFiles!(body, allAttachments);
        if (mounted) {
          widget.controller.clear();
          setState(() => _selectedFiles.clear());
        }

        return;
      }

      if (!mounted) return;
      final bloc = context.read<ChatBloc>();
      final clientId = newClientLocalId();
      bloc.add(
        ChatStartSendingMessage(
          clientId: clientId,
          text: text,
          attachments: uploadedAttachments.isEmpty ? null : uploadedAttachments,
          largeFiles: largeFileRefs,
        ),
      );
      widget.controller.clear();
      setState(() => _selectedFiles.clear());

      for (final ref in largeFileRefs) {
        try {
          final fileId = await widget.uploadLargeFile!(
            ref.path,
            ref.filename,
            ref.size,
            (sent, total) {
              if (mounted) {
                bloc.add(ChatUploadProgress(clientId, ref.filename, sent, total));
              }
            },
          );
          if (fileId != null && fileId != 0 && mounted) {
            bloc.add(ChatUploadFileComplete(clientId, ref.filename, fileId));
          } else {
            if (mounted && messenger != null) {
              messenger.showSnackBar(
                SnackBar(content: Text('Ошибка загрузки: ${ref.filename}')),
              );
              bloc.add(ChatCancelPendingMessage(clientId));
            }

            return;
          }
        } catch (_) {
          if (mounted && messenger != null) {
            messenger.showSnackBar(
              SnackBar(content: Text('Ошибка загрузки: ${ref.filename}')),
            );
            bloc.add(ChatCancelPendingMessage(clientId));
          }

          return;
        }
      }
      if (mounted) {
        bloc.add(ChatSubmitPendingMessage(clientId));
      }

      return;
    }

    final attachments = uploadedAttachments.isEmpty
        ? null
        : uploadedAttachments;
    widget.onSendMessage(text, attachments: attachments);
    widget.controller.clear();
    setState(() => _selectedFiles.clear());
  }

  Future<void> _pickFile() async {
    if (!widget.isEnabled) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final toAdd = <PlatformFile>[];
    for (final file in result.files) {
      if (file.path == null && (file.bytes == null || file.bytes!.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось получить файл')),
          );
        }

        continue;
      }
      toAdd.add(file);
    }

    if (toAdd.isNotEmpty) {
      setState(() => _selectedFiles.addAll(toAdd));
    }
  }

  void _clearFiles() {
    setState(() => _selectedFiles.clear());
  }

  Future<void> _onFilesDropped(DropDoneDetails details) async {
    setState(() => _isDraggingFile = false);
    if (!widget.isEnabled) {
      return;
    }

    if (details.files.isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    final toAdd = <PlatformFile>[];
    for (final item in details.files) {
      if (item is! DropItemFile) {
        continue;
      }

      try {
        final name = item.name.isNotEmpty
            ? item.name
            : item.path.split(RegExp(r'[/\\]')).last;
        if (name.isEmpty) {
          continue;
        }

        final size = await item.length();
        final path = item.path;
        if (path.isEmpty) {
          final bytes = await item.readAsBytes();
          if (bytes.isEmpty) {
            continue;
          }

          if (bytes.length > _chatAttachmentMaxBytes) {
            if (mounted && messenger != null) {
              messenger.showSnackBar(
                SnackBar(content: Text('Файл слишком большой: $name')),
              );
            }

            continue;
          }
          toAdd.add(PlatformFile(name: name, size: bytes.length, bytes: bytes));
        } else {
          if (size > _largeFileThresholdBytes &&
              widget.uploadLargeFile == null &&
              size > _chatAttachmentMaxBytes) {
            if (mounted && messenger != null) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Большие файлы не поддерживаются'),
                ),
              );
            }

            continue;
          }
          if (size <= _chatAttachmentMaxBytes) {
            final bytes = await item.readAsBytes();
            toAdd.add(
              PlatformFile(
                name: name,
                path: path,
                size: size,
                bytes: bytes.isEmpty ? null : bytes,
              ),
            );
          } else {
            toAdd.add(PlatformFile(name: name, path: path, size: size));
          }
        }
      } catch (_) {
        if (mounted && messenger != null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Не удалось добавить файл')),
          );
        }
      }
    }
    if (toAdd.isNotEmpty && mounted) {
      setState(() => _selectedFiles.addAll(toAdd));
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedFiles.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Вложения (${_selectedFiles.length})',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _clearFiles,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Очистить'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_selectedFiles.length, (i) {
                        final f = _selectedFiles[i];
                        return _AttachmentPreviewTile(
                          name: f.name,
                          fileSize: f.size,
                          onRemove: () => _removeFile(i),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.isSending) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Отправка...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHigh
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.12,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.isEnabled)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickFile,
                              borderRadius: BorderRadius.circular(20),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.attach_file_rounded,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Focus(
                            onKeyEvent: (_, event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.enter) {
                                if (!HardwareKeyboard.instance.isShiftPressed) {
                                  _send();
                                  return KeyEventResult.handled;
                                }
                              }

                              return KeyEventResult.ignored;
                            },
                            child: TextField(
                              controller: widget.controller,
                              enabled: widget.isEnabled,
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: widget.hintText ?? 'Сообщение',
                                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.65),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ).copyWith(left: 4, right: 8),
                              ),
                            ),
                          ),
                        ),
                        if (widget.isEnabled)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _toggleEmojiPicker,
                              borderRadius: BorderRadius.circular(20),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.emoji_emotions_outlined,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: widget.isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.isEnabled ? _send : null,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: widget.isSending
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: widget.isEnabled
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            if (_showEmojiPicker) _buildEmojiPickerInline(theme),
          ],
        ),
      ),
    );
    return DropTarget(
      onDragEntered: widget.isEnabled
          ? (_) => setState(() => _isDraggingFile = true)
          : null,
      onDragExited: widget.isEnabled
          ? (_) => setState(() => _isDraggingFile = false)
          : null,
      onDragDone: widget.isEnabled ? _onFilesDropped : null,
      enable: widget.isEnabled,
      child: Stack(
        clipBehavior: Clip.none,
        children: [content, if (_isDraggingFile) _buildDropOverlay(context)],
      ),
    );
  }

  Widget _buildEmojiPickerInline(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerLowest;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 280,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: EmojiPicker(
        textEditingController: widget.controller,
        config: Config(
          height: 256,
          checkPlatformCompatibility: true,
          locale: const Locale('ru'),
          viewOrderConfig: const ViewOrderConfig(),
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax:
                28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1.0),
          ),
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: const CategoryViewConfig(),
          bottomActionBarConfig: const BottomActionBarConfig(
            enabled: false,
            showSearchViewButton: false,
            showBackspaceButton: false,
          ),
          searchViewConfig: const SearchViewConfig(),
        ),
      ),
    );
  }

  Widget _buildDropOverlay(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Отпустите файлы, чтобы прикрепить',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreviewTile extends StatelessWidget {
  final String name;
  final int fileSize;
  final VoidCallback onRemove;

  const _AttachmentPreviewTile({
    required this.name,
    required this.fileSize,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 56.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(width: size, height: size, child: _iconContent(theme, size)),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: theme.colorScheme.errorContainer,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onRemove,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Text(
              fileSize > 0 ? '$name (${(fileSize / 1024).ceil()} КБ)' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconContent(ThemeData theme, double size) {
    IconData icon = Icons.insert_drive_file_rounded;
    if (AttachmentType.isImageFilename(name)) {
      icon = Icons.image_outlined;
    } else if (AttachmentType.isVideoFilename(name)) {
      icon = Icons.videocam_rounded;
    } else if (AttachmentType.isAudioFilename(name)) {
      icon = Icons.audiotrack_rounded;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(icon, size: 28, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

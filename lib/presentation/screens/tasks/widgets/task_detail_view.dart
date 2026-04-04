import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:voosu/core/file_stream.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/core/date_formatter.dart';
import 'package:voosu/core/util.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/entities/task_comment.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/domain/usecases/chat/upload_chat_file_usecase.dart';
import 'package:voosu/domain/usecases/project/add_task_comment_usecase.dart';
import 'package:voosu/domain/usecases/project/get_task_comments_usecase.dart';
import 'package:voosu/domain/usecases/project/get_task_history_usecase.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_input_bar.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_event.dart';
import 'package:voosu/presentation/widgets/code_block_builder.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class TaskDetailView extends StatefulWidget {
  final Task task;
  final int projectId;
  final VoidCallback? onBack;

  const TaskDetailView({
    super.key,
    required this.task,
    required this.projectId,
    this.onBack,
  });

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView>
    with SingleTickerProviderStateMixin {
  List<User>? _members;
  List<TaskComment> _comments = [];
  List<ProjectActivity> _history = [];
  bool _commentsLoading = false;
  bool _historyLoading = false;
  final TextEditingController _commentController = TextEditingController();
  bool _commentSending = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMembers();
    _loadComments();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _commentsLoading = true);
    try {
      final list = await di.sl<GetTaskCommentsUseCase>()(widget.task.id);
      if (mounted) {
        setState(() => _comments = list);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _comments = []);
      }
    } finally {
      if (mounted) {
        setState(() => _commentsLoading = false);
      }
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted) {
      return;
    }
    setState(() => _historyLoading = true);
    try {
      final list = await di.sl<GetTaskHistoryUseCase>()(widget.task.id);
      if (mounted) {
        setState(() => _history = list);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _history = []);
      }
    } finally {
      if (mounted) {
        setState(() => _historyLoading = false);
      }
    }
  }

  Future<void> _sendComment(
    String text, {
    List<AttachmentUpload>? attachments,
  }) async {
    if (text.isEmpty && (attachments == null || attachments.isEmpty)) {
      return;
    }

    if (_commentSending) {
      return;
    }

    setState(() => _commentSending = true);
    try {
      final body =
          text.isEmpty && (attachments != null && attachments.isNotEmpty)
          ? '[файлы]'
          : text;
      final fileIds = attachments
              ?.map((a) => int.tryParse(a.fileId))
              .whereType<int>()
              .toList() ??
          <int>[];
      await di.sl<AddTaskCommentUseCase>()(
        widget.task.id,
        body,
        attachmentFileIds: fileIds,
      );
      _commentController.clear();
      await _loadComments();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось добавить комментарий')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _commentSending = false);
      }
    }
  }

  Future<String?> _uploadCommentFile(
    String filename,
    Stream<List<int>> chunkStream,
    int totalBytes, [
    void Function(int sentBytes, int? totalBytes)? onProgress,
  ]) async {
    try {
      return await di.sl<UploadChatFileUseCase>().call(
        filename: filename,
        chunkStream: chunkStream,
        totalBytes: totalBytes,
        onProgress: onProgress,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadCommentLargeFile(
    String path,
    String filename,
    int size, [
    void Function(int sentBytes, int? totalBytes)? onProgress,
  ]) async {
    try {
      final stream = streamFromPath(path, size);
      return await di.sl<UploadChatFileUseCase>().call(
        filename: filename,
        chunkStream: stream,
        totalBytes: size,
        onProgress: onProgress,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadAttachment(int fileId, String filename) async {
    try {
      final bytes = await di.sl<AccountRepository>().getFile(fileId.toString());
      if (bytes.isEmpty || !mounted) {
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${filename.split(RegExp(r'[/\\]')).last}');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось скачать файл')),
        );
      }
    }
  }

  void _loadMembers() {
    try {
      final projectBloc = context.read<ProjectBloc>();
      projectBloc.add(ProjectMembersLoadRequested(widget.projectId));

      projectBloc.stream.listen((state) {
        if (state.members.isNotEmpty && mounted) {
          setState(() {
            _members = state.members.map((m) => m.user).toList();
          });
        }
      });
    } catch (e) {
      Logs().d('TaskDetailView: _loadMembers', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (widget.task.labels.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.task.labels.map((l) {
                          final color = labelColorFromHex(l.color);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              l.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (widget.task.description.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MarkdownBody(
                          data: widget.task.description,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).textTheme.bodyLarge,
                            h1: Theme.of(context).textTheme.headlineSmall,
                            h2: Theme.of(context).textTheme.titleLarge,
                            h3: Theme.of(context).textTheme.titleMedium,
                            listIndent: 24,
                            blockquote: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontStyle: FontStyle.italic),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 4,
                                ),
                              ),
                            ),
                            code: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          builders: {'pre': CodeBlockBuilder()},
                        ),
                      ),
                    ],
                    if (widget.task.attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Вложения',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: widget.task.attachments.map((a) {
                          return InkWell(
                            onTap: () => _downloadAttachment(a.fileId, a.filename),
                            child: Chip(
                              avatar: const Icon(Icons.attach_file, size: 18),
                              label: Text(a.filename),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Создано',
                      value: DateFormatter.formatDate(widget.task.createdAt),
                      icon: Icons.access_time,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Постановщик',
                      value: userDisplayNameForId(
                        _members,
                        widget.task.assigner,
                      ),
                      icon: Icons.person_add,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Исполнитель',
                      value: userDisplayNameForId(
                        _members,
                        widget.task.executor,
                      ),
                      icon: Icons.person,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                text: 'Комментарии',
                icon: Icon(Icons.chat_bubble_outline, size: 20),
              ),
              Tab(text: 'История', icon: Icon(Icons.history, size: 20)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [_buildCommentsTab(context), _buildHistoryTab(context)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_commentsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  ..._comments.map(
                    (c) => _CommentTile(
                      comment: c,
                      userName: userDisplayNameForId(_members, c.userId),
                      onDownloadAttachment: _downloadAttachment,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ChatInputBar(
          controller: _commentController,
          onSendMessage: (text, {attachments, mention}) =>
              _sendComment(text, attachments: attachments),
          isEnabled: !_commentSending,
          isSending: _commentSending,
          uploadFile: _uploadCommentFile,
          uploadLargeFile: _uploadCommentLargeFile,
          onSendWithLargeFiles: (text, attachments) =>
              _sendComment(text, attachments: attachments),
          hintText: 'Написать комментарий...',
        ),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Text(
          'Нет записей',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final a = _history[index];
        return _HistoryTile(
          activity: a,
          userName: userDisplayNameForId(_members, a.userId),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final crossAlign = CrossAxisAlignment.start;
    final textAlign = TextAlign.left;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: crossAlign,
            children: [
              Text(
                label,
                textAlign: textAlign,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: textAlign,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final TaskComment comment;
  final String userName;
  final void Function(int fileId, String filename) onDownloadAttachment;

  const _CommentTile({
    required this.comment,
    required this.userName,
    required this.onDownloadAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                userName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormatter.formatDate(comment.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(comment.body, style: theme.textTheme.bodyMedium),
          if (comment.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: comment.attachments.map((a) {
                return InkWell(
                  onTap: () => onDownloadAttachment(a.fileId, a.filename),
                  child: Chip(
                    avatar: const Icon(Icons.attach_file, size: 18),
                    label: Text(a.filename),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ProjectActivity activity;
  final String userName;

  const _HistoryTile({required this.activity, required this.userName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.actionLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormatter.formatDate(activity.createdAt)} - $userName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


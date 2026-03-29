import 'package:flutter/material.dart';
import 'package:voosu/data/services/upload_queue_service.dart';

String _formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) {
    return '-';
  }

  if (bytes < 1024) {
    return '$bytes B';
  }

  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(bytes < 10 * 1024 ? 1 : 0)} KB';
  }

  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _statusLabel(UploadQueueItem item) {
  switch (item.phase) {
    case UploadQueuePhase.waiting:
      return 'Ожидание загрузки';
    case UploadQueuePhase.uploading:
      final pct = (item.progress * 100).round();
      return 'Идет загрузка · $pct%';
    case UploadQueuePhase.complete:
      return 'Загрузка завершена';
    case UploadQueuePhase.error:
      return 'Сетевая ошибка';
  }
}

class UploadQueuePanel extends StatelessWidget {
  const UploadQueuePanel({super.key, required this.service});

  final UploadQueueService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Загрузки',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: service.items.isEmpty
                ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Нет активных загрузок',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                : ListView.separated(
                  shrinkWrap: true,
                  itemCount: service.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = service.items[index];
                    return _UploadRow(item: item);
                  },
                ),
            ),
          ],
        );
      },
    );
  }
}

class _UploadRow extends StatelessWidget {
  const _UploadRow({required this.item});

  final UploadQueueItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final showDeterminate = item.phase == UploadQueuePhase.uploading &&
        item.totalBytes != null &&
        item.totalBytes! > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: showDeterminate
                    ? SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value: item.progress.clamp(0.0, 1.0),
                      ),
                    )
                    : item.phase == UploadQueuePhase.uploading || item.phase == UploadQueuePhase.waiting
                    ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                    : Icon(
                      item.phase == UploadQueuePhase.complete
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      color: item.phase == UploadQueuePhase.complete
                          ? scheme.primary
                          : scheme.error,
                      size: 28,
                    ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.filename,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_formatFileSize(item.totalBytes)})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.phase == UploadQueuePhase.error &&
                            item.errorMessage != null &&
                            item.errorMessage!.isNotEmpty
                        ? '${_statusLabel(item)}: ${item.errorMessage}'
                        : _statusLabel(item),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadQueueNavButton extends StatelessWidget {
  const UploadQueueNavButton({super.key, required this.service});

  final UploadQueueService service;

  Future<void> _openPanel(BuildContext context) async {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    if (isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(ctx).bottom + 16,
            top: 8,
          ),
          child: UploadQueuePanel(service: service),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 8, 24),
          content: SizedBox(
            width: 400,
            child: UploadQueuePanel(service: service),
          ),
        ),
      );
    }
    service.closePanel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = service.hasActiveWork;

    return Tooltip(
      message: 'Загрузки',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPanel(context),
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 26,
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
                if (active)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

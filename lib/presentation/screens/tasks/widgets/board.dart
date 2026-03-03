import 'package:flutter/material.dart';
import 'package:voosu/core/date_formatter.dart';
import 'package:voosu/core/util.dart';
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/domain/entities/board_column.dart';
import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/entities/task.dart';

class Board extends StatelessWidget {
  final List<Task> tasks;
  final List<BoardColumn> columns;
  final Function(Task) onTaskTap;
  final Function(Task, int)? onTaskColumnIdChanged;
  final Map<int, String> executorNames;

  const Board({
    super.key,
    required this.tasks,
    required this.columns,
    required this.onTaskTap,
    this.onTaskColumnIdChanged,
    this.executorNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final padding = isMobile ? 8.0 : 16.0;
    final columnSpacing = isMobile ? 12.0 : 16.0;
    final columnWidth = isMobile ? 280.0 : null;

    if (columns.isEmpty) {
      return _BoardEmptyState(padding: padding);
    }

    final columnWidgets = columns.map((col) {
      final columnTasks = tasks.where((t) => t.columnId == col.id).toList();
      return _BoardColumn(
        column: col,
        color: labelColorFromHex(col.color),
        tasks: columnTasks,
        executorNames: executorNames,
        onTaskTap: onTaskTap,
        onTaskColumnIdChanged: onTaskColumnIdChanged,
      );
    }).toList();

    if (isMobile) {
      return Container(
        padding: EdgeInsets.all(padding),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: columnWidgets.length,
          itemBuilder: (context, index) {
            return Container(
              width: columnWidth,
              margin: EdgeInsets.only(
                right: index < columnWidgets.length - 1 ? columnSpacing : 0,
              ),
              child: columnWidgets[index],
            );
          },
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columnWidgets.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < columnWidgets.length - 1 ? columnSpacing : 0,
              ),
              child: column,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BoardEmptyState extends StatelessWidget {
  final double padding;

  const _BoardEmptyState({required this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_column_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Нет колонок',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте колонку для начала работы',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  final BoardColumn column;
  final Color color;
  final List<Task> tasks;
  final Map<int, String> executorNames;
  final Function(Task) onTaskTap;
  final Function(Task, int)? onTaskColumnIdChanged;

  const _BoardColumn({
    required this.column,
    required this.color,
    required this.tasks,
    required this.executorNames,
    required this.onTaskTap,
    this.onTaskColumnIdChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final padding = isMobile ? 10.0 : 12.0;
    final spacing = isMobile ? 8.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ColumnHeader(
          column: column,
          color: color,
          taskCount: tasks.length,
          padding: padding,
          spacing: spacing,
          isMobile: isMobile,
        ),
        SizedBox(height: spacing),
        Expanded(
          child: DragTarget<Task>(
            onAcceptWithDetails: (details) {
              final task = details.data;
              if (onTaskColumnIdChanged != null && task.columnId != column.id) {
                onTaskColumnIdChanged!(task, column.id);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isDraggingOver = candidateData.isNotEmpty;
              return Container(
                decoration: BoxDecoration(
                  color: isDraggingOver
                      ? color.withValues(alpha: 0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Нет задач',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _TaskCard(
                            task: task,
                            executorName: executorNames[task.executor],
                            onTap: () => onTaskTap(task),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final BoardColumn column;
  final Color color;
  final int taskCount;
  final double padding;
  final double spacing;
  final bool isMobile;

  const _ColumnHeader({
    required this.column,
    required this.color,
    required this.taskCount,
    required this.padding,
    required this.spacing,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: isMobile ? 16 : 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              column.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: spacing),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 8,
              vertical: isMobile ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$taskCount',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 12 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final ProjectLabel label;

  const _LabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = labelColorFromHex(label.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label.name,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final String? executorName;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    this.executorName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final padding = isMobile ? 10.0 : 12.0;
    final margin = isMobile ? 6.0 : 8.0;

    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 13 : 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Card(
          margin: EdgeInsets.only(bottom: margin),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Text(
              task.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
        ),
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: margin),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  maxLines: isMobile ? 2 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.labels.isNotEmpty) ...[
                  SizedBox(height: isMobile ? 6 : 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: task.labels.map((l) => _LabelChip(label: l)).toList(),
                  ),
                ],
                if (task.description.isNotEmpty) ...[
                  SizedBox(height: isMobile ? 6 : 8),
                  Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: isMobile ? 11 : null,
                    ),
                    maxLines: isMobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: isMobile ? 6 : 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: isMobile ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: isMobile ? 3 : 4),
                    Text(
                      DateFormatter.formatRelativeDate(task.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 11 : null,
                      ),
                    ),
                  ],
                ),
                if (executorName != null && executorName!.isNotEmpty) ...[
                  SizedBox(height: isMobile ? 4 : 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: isMobile ? 11 : 12,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: isMobile ? 3 : 4),
                      Expanded(
                        child: Text(
                          executorName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: isMobile ? 11 : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

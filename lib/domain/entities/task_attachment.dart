import 'package:equatable/equatable.dart';

class TaskAttachment extends Equatable {
  final int fileId;
  final String filename;
  final String mimeType;
  final int size;

  const TaskAttachment({
    required this.fileId,
    required this.filename,
    this.mimeType = '',
    this.size = 0,
  });

  @override
  List<Object?> get props => [fileId, filename, mimeType, size];
}

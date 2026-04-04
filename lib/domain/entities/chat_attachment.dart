class ChatAttachment {
  final String fileId;
  final String filename;
  final String mimeType;
  final int size;
  final int type;

  const ChatAttachment({
    required this.fileId,
    required this.filename,
    this.mimeType = '',
    this.size = 0,
    this.type = 0,
  });
}

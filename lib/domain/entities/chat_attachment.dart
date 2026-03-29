class ChatAttachment {
  final int fileId;
  final String filename;
  final String mimeType;
  final int size;
  final int type;
  final String? externalUrl;

  const ChatAttachment({
    required this.fileId,
    required this.filename,
    this.mimeType = '',
    this.size = 0,
    this.type = 0,
    this.externalUrl,
  });
}

import 'package:voosu/core/attachment_type_helper.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';

class MixedSendItem {
  final int itemType;
  final String content;
  final String imageFileId;

  const MixedSendItem({
    required this.itemType,
    this.content = '',
    this.imageFileId = '',
  });
}

bool shouldSendAsMixedMessage(String content, List<AttachmentUpload>? attachments) {
  final t = content.trim();
  if (t.isEmpty || attachments == null || attachments.isEmpty) {
    return false;
  }
  for (final a in attachments) {
    if (a.fileId.isEmpty || !AttachmentType.isImageFilename(a.filename)) {
      return false;
    }
  }
  return true;
}

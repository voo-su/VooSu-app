import 'package:voosu/core/attachment_type_helper.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';

class MixedSendItem {
  final int itemType;
  final String content;
  final int imageFileId;

  const MixedSendItem({
    required this.itemType,
    this.content = '',
    this.imageFileId = 0,
  });
}

bool shouldSendAsMixedMessage(String content, List<AttachmentUpload>? attachments) {
  final t = content.trim();
  if (t.isEmpty || attachments == null || attachments.isEmpty) {
    return false;
  }
  for (final a in attachments) {
    if (a.fileId == 0 || !AttachmentType.isImageFilename(a.filename)) {
      return false;
    }
  }
  return true;
}

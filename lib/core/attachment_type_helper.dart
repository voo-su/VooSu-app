class AttachmentType {
  static const int unknown = 0;
  static const int image = 1;
  static const int document = 2;
  static const int video = 3;
  static const int audio = 4;

  static const List<String> _imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
    'ico',
  ];
  static const List<String> _videoExtensions = [
    'mp4',
    'webm',
    'mov',
    'avi',
    'mkv',
    'm4v',
  ];
  static const List<String> _audioExtensions = [
    'mp3',
    'wav',
    'ogg',
    'm4a',
    'aac',
    'flac',
  ];

  static bool isImageFilename(String filename) {
    final ext = (filename.split('.').lastOrNull ?? '').toLowerCase();
    return _imageExtensions.contains(ext);
  }

  static bool isVideoFilename(String filename) {
    final ext = (filename.split('.').lastOrNull ?? '').toLowerCase();
    return _videoExtensions.contains(ext);
  }

  static bool isAudioFilename(String filename) {
    final ext = (filename.split('.').lastOrNull ?? '').toLowerCase();
    return _audioExtensions.contains(ext);
  }

  static bool isImageBytes(List<int> bytes) {
    if (bytes.length < 4) {
      return false;
    }

    // PNG
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) {
      return true;
    }

    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return true;
    }

    // GIF
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return true;
    }

    // WebP
    if (bytes.length >= 12 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42) {
      return true;
    }

    return false;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaCacheService {
  final AccountRepository _accountRepository;
  Directory? _cacheDir;
  static const String _mediaSubdir = 'media';
  static const int _maxCacheBytes = 200 * 1024 * 1024;
  static const int _evictTargetBytes = 150 * 1024 * 1024;

  MediaCacheService(this._accountRepository);

  Future<Directory> _getCacheDir() async {
    _cacheDir ??= Directory(
      p.join((await getTemporaryDirectory()).path, _mediaSubdir),
    );
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }

    return _cacheDir!;
  }

  static String _fileNameFor(String fileId) {
    final bytes = utf8.encode(fileId);
    final b64 = base64UrlEncode(bytes).replaceAll('/', '_');
    if (b64.length > 180) {
      return '${b64.substring(0, 180)}.bin';
    }

    return b64;
  }

  Future<List<int>> getFile(String fileId) async {
    final dir = await _getCacheDir();
    final file = File(p.join(dir.path, _fileNameFor(fileId)));

    if (await file.exists()) {
      try {
        return await file.readAsBytes();
      } catch (e) {
        Logs().d('MediaCacheService: не удалось прочитать кэш $fileId: $e');
      }
    }

    final bytes = await _accountRepository.getFile(fileId);
    try {
      await _maybeEvict(dir, bytes.length);
      await file.writeAsBytes(bytes);
    } catch (e) {
      Logs().d('MediaCacheService: не удалось записать кэш $fileId: $e');
    }

    return bytes;
  }

  Future<String?> getCachedPath(String fileId) async {
    final dir = await _getCacheDir();
    final file = File(p.join(dir.path, _fileNameFor(fileId)));
    if (await file.exists()) {
      return file.path;
    }

    return null;
  }

  Future<void> _maybeEvict(Directory dir, int incomingSize) async {
    try {
      int total = 0;
      final list = await dir.list().toList();
      final files = <FileSystemEntity>[];
      for (final e in list) {
        if (e is File) {
          total += await e.length();
          files.add(e);
        }
      }

      if (total + incomingSize <= _maxCacheBytes) {
        return;
      }

      files.sort((a, b) {
        final am = (a as File).lastModifiedSync();
        final bm = (b as File).lastModifiedSync();

        return am.compareTo(bm);
      });

      for (final f in files) {
        if (total <= _evictTargetBytes) {
          break;
        }

        final file = f as File;
        final len = await file.length();
        await file.delete();
        total -= len;
        Logs().d('MediaCacheService: удалён старый кэш ${file.path}');
      }
    } catch (e) {
      Logs().d('MediaCacheService: evict error: $e');
    }
  }

  Future<void> clearCache() async {
    final dir = await _getCacheDir();
    try {
      await for (final entity in dir.list()) {
        if (entity is File) await entity.delete();
      }
    } catch (e) {
      Logs().e('MediaCacheService: clearCache', e);
    }
  }
}

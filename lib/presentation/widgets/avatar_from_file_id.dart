import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:voosu/domain/repositories/account_repository.dart';

class AvatarFromFileId extends StatefulWidget {
  final String? fileId;
  final String letter;
  final double size;
  final AccountRepository? accountRepository;

  const AvatarFromFileId({
    super.key,
    this.fileId,
    this.letter = '?',
    this.size = 48,
    this.accountRepository,
  });

  @override
  State<AvatarFromFileId> createState() => _AvatarFromFileIdState();
}

class _AvatarFromFileIdState extends State<AvatarFromFileId> {
  Uint8List? _bytes;
  bool _loading = false;

  bool get _hasFileId =>
      widget.fileId != null && widget.fileId!.trim().isNotEmpty;

  Future<void> _loadBytes() async {
    if (!_hasFileId || widget.accountRepository == null) {
      return;
    }
    if (_bytes != null) {
      return;
    }
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    try {
      final bytes = await widget.accountRepository!.getFile(widget.fileId!.trim());
      if (mounted) {
        setState(() {
          _bytes = Uint8List.fromList(bytes);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasFileId && _bytes == null && !_loading) {
      _loadBytes();
    }
  }

  @override
  void didUpdateWidget(covariant AvatarFromFileId oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileId != widget.fileId) {
      _bytes = null;
      _loading = false;
      if (_hasFileId) {
        _loadBytes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final hasImage = _bytes != null && _bytes!.isNotEmpty;

    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: theme.primaryContainer,
      backgroundImage: hasImage ? MemoryImage(_bytes!) : null,
      child: hasImage
          ? null
          : Text(
              widget.letter,
              style: TextStyle(
                color: theme.onPrimaryContainer,
                fontSize: widget.size * 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

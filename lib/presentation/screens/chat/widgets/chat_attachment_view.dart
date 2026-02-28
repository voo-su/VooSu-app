import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:voosu/core/attachment_type_helper.dart';
import 'package:voosu/domain/entities/chat_attachment.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

class ChatAttachmentView extends StatefulWidget {
  final ChatAttachment attachment;
  final Future<List<int>?> Function(int fileId) onLoadContent;
  final Future<void> Function(int fileId, String filename)? onDownload;
  final Color textColor;

  const ChatAttachmentView({
    super.key,
    required this.attachment,
    required this.onLoadContent,
    this.onDownload,
    required this.textColor,
  });

  @override
  State<ChatAttachmentView> createState() => _ChatAttachmentViewState();
}

class _ChatAttachmentViewState extends State<ChatAttachmentView> {
  List<int>? _bytes;
  bool _loading = true;
  bool _error = false;
  Player? _videoPlayer;
  VideoController? _videoController;
  String? _videoFilePath;
  just_audio.AudioPlayer? _audioPlayer;
  bool _videoSeekDragging = false;
  double _videoSeekValue = 0;
  bool _audioSeekDragging = false;
  double _audioSeekValue = 0;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final bytes = await widget.onLoadContent(widget.attachment.fileId);
    if (!mounted) {
      return;
    }
    setState(() {
      _bytes = bytes;
      _loading = bytes == null;
      _error = bytes == null;
    });
    if (bytes != null && bytes.isNotEmpty) {
      if (widget.attachment.type == AttachmentType.video) {
        await _initVideo(bytes);
      } else if (widget.attachment.type == AttachmentType.audio) {
        await _initAudio(bytes);
      }
    }
  }

  Future<void> _initVideo(List<int> bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final name = widget.attachment.filename.split(RegExp(r'[/\\]')).last;
      final safeName = name.isEmpty
        ? 'video_${widget.attachment.fileId}'
        : name;
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(bytes);
      if (!mounted) {
        return;
      }

      final player = Player();
      final controller = VideoController(player);
      await player.open(Media(Uri.file(file.path).toString()), play: false);
      if (!mounted) {
        return;
      }

      setState(() {
        _videoPlayer = player;
        _videoController = controller;
        _videoFilePath = file.path;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = true);
      }
    }
  }

  Future<void> _initAudio(List<int> bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final name = widget.attachment.filename.split(RegExp(r'[/\\]')).last;
      final safeName = name.isEmpty
        ? 'audio_${widget.attachment.fileId}'
        : name;
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(bytes);
      if (!mounted) {
        return;
      }

      final player = just_audio.AudioPlayer();
      await player.setFilePath(file.path);
      if (!mounted) {
        return;
      }

      setState(() => _audioPlayer = player);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _videoController = null;
    _videoPlayer?.dispose();
    _videoPlayer = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;
    super.dispose();
  }

  void _showImageFullscreen() {
    if (_bytes == null || _bytes!.isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.memory(
                Uint8List.fromList(_bytes!),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoFullscreen() {
    if (_videoFilePath == null) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _FullscreenVideoDialog(filePath: _videoFilePath!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading && !_error) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.textColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Загрузка...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }
    if (_error) {
      return _buildDocumentRow(
        theme,
        onTap: widget.onDownload != null ? () => widget.onDownload!(
          widget.attachment.fileId,
          widget.attachment.filename,
        )
        : null,
      );
    }

    switch (widget.attachment.type) {
      case AttachmentType.image:
        return _buildImage(theme);
      case AttachmentType.video:
        return _buildVideo(theme);
      case AttachmentType.audio:
        return _buildAudio(theme);
      case AttachmentType.document:
      case AttachmentType.unknown:
      default:
        return _buildDocumentRow(
          theme,
          onTap: widget.onDownload != null ? () => widget.onDownload!(
            widget.attachment.fileId,
            widget.attachment.filename,
          )
          : null,
        );
    }
  }

  Widget _buildImage(ThemeData theme) {
    if (_bytes == null || _bytes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: _showImageFullscreen,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            Uint8List.fromList(_bytes!),
            fit: BoxFit.cover,
            width: 220,
            height: 180,
            errorBuilder: (_, e, st) =>
                _buildDocumentRow(theme, onTap: _showImageFullscreen),
          ),
        ),
      ),
    );
  }

  Widget _buildVideo(ThemeData theme) {
    final player = _videoPlayer;
    final controller = _videoController;
    if (player == null || controller == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_rounded,
              size: 20,
              color: widget.textColor.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              widget.attachment.filename.isNotEmpty
                ? widget.attachment.filename
                : 'Видео',
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.textColor.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 220,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              Video(
                controller: controller,
                controls: NoVideoControls,
                fit: BoxFit.cover,
              ),
              GestureDetector(
                onTap: () => player.playOrPause(),
                child: StreamBuilder<bool>(
                  stream: player.stream.playing,
                  initialData: player.state.playing,
                  builder: (context, snapshot) {
                    final playing = snapshot.data ?? false;
                    return Container(
                      color: Colors.black26,
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 22,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    padding: const EdgeInsets.all(4),
                    minimumSize: const Size(32, 32),
                  ),
                  onPressed: _showVideoFullscreen,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: StreamBuilder<Duration>(
                    stream: player.stream.position,
                    initialData: player.state.position,
                    builder: (context, posSnapshot) {
                      return StreamBuilder<Duration>(
                        stream: player.stream.duration,
                        initialData: player.state.duration,
                        builder: (context, durSnapshot) {
                          final pos = posSnapshot.data ?? Duration.zero;
                          final dur = durSnapshot.data ?? Duration.zero;
                          final durMs = dur.inMilliseconds.clamp(1, 0x7fffffff);
                          final value = _videoSeekDragging
                              ? _videoSeekValue
                              : (pos.inMilliseconds / durMs).clamp(0.0, 1.0);
                          return Row(
                            children: [
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white38,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: value,
                                    onChanged: (v) => setState(() {
                                      _videoSeekDragging = true;
                                      _videoSeekValue = v;
                                    }),
                                    onChangeEnd: (v) {
                                      final to = Duration(
                                        milliseconds: (v * durMs).round(),
                                      );
                                      player.seek(to);
                                      setState(
                                        () => _videoSeekDragging = false,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudio(ThemeData theme) {
    final player = _audioPlayer;
    if (player == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audiotrack_rounded,
              size: 20,
              color: widget.textColor.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              widget.attachment.filename.isNotEmpty
                  ? widget.attachment.filename
                  : 'Аудио',
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.textColor.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<just_audio.PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data ?? player.playerState;
              final playing = state.playing;
              return IconButton(
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: widget.textColor,
                ),
                onPressed: () async {
                  if (playing) {
                    await player.pause();
                  } else {
                    await player.play();
                  }
                },
              );
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.attachment.filename.isNotEmpty
                      ? widget.attachment.filename
                      : 'Аудио',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.textColor.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, posSnapshot) {
                    final pos = posSnapshot.data ?? Duration.zero;
                    final dur = player.duration ?? Duration.zero;
                    final durMs = dur.inMilliseconds.clamp(1, 0x7fffffff);
                    final value = _audioSeekDragging
                        ? _audioSeekValue
                        : (pos.inMilliseconds / durMs).clamp(0.0, 1.0);
                    return SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: value,
                        activeColor: widget.textColor,
                        inactiveColor: widget.textColor.withValues(alpha: 0.4),
                        onChanged: (v) => setState(() {
                          _audioSeekDragging = true;
                          _audioSeekValue = v;
                        }),
                        onChangeEnd: (v) {
                          player.seek(
                            Duration(milliseconds: (v * durMs).round()),
                          );
                          setState(() => _audioSeekDragging = false);
                        },
                      ),
                    );
                  },
                ),
                StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, posSnapshot) {
                    final pos = posSnapshot.data ?? Duration.zero;
                    final dur = player.duration ?? Duration.zero;
                    return Text(
                      '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.textColor.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildDocumentRow(ThemeData theme, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file_rounded,
              size: 18,
              color: widget.textColor.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.attachment.filename.isNotEmpty
                    ? widget.attachment.filename
                    : 'Вложение',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: widget.textColor.withValues(alpha: 0.9),
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenVideoDialog extends StatefulWidget {
  final String filePath;

  const _FullscreenVideoDialog({required this.filePath});

  @override
  State<_FullscreenVideoDialog> createState() => _FullscreenVideoDialogState();
}

class _FullscreenVideoDialogState extends State<_FullscreenVideoDialog> {
  Player? _player;
  VideoController? _videoController;
  bool _initialized = false;
  String? _error;
  bool _seekDragging = false;
  double _seekValue = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final player = Player();
      final controller = VideoController(player);
      await player.open(
        Media(Uri.file(widget.filePath).toString()),
        play: false,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _player = player;
        _videoController = controller;
        _initialized = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _videoController = null;
    _player?.dispose();
    _player = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_initialized && _player != null && _videoController != null)
            Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                Video(
                  controller: _videoController!,
                  controls: NoVideoControls,
                  fit: BoxFit.contain,
                ),
                GestureDetector(
                  onTap: () => _player!.playOrPause(),
                  child: StreamBuilder<bool>(
                    stream: _player!.stream.playing,
                    initialData: _player!.state.playing,
                    builder: (context, snapshot) {
                      final playing = snapshot.data ?? false;
                      return Container(
                        color: Colors.transparent,
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 80,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: StreamBuilder<Duration>(
                      stream: _player!.stream.position,
                      initialData: _player!.state.position,
                      builder: (context, posSnapshot) {
                        return StreamBuilder<Duration>(
                          stream: _player!.stream.duration,
                          initialData: _player!.state.duration,
                          builder: (context, durSnapshot) {
                            final pos = posSnapshot.data ?? Duration.zero;
                            final dur = durSnapshot.data ?? Duration.zero;
                            final durMs = dur.inMilliseconds.clamp(
                              1,
                              0x7fffffff,
                            );
                            final value = _seekDragging
                                ? _seekValue
                                : (pos.inMilliseconds / durMs).clamp(0.0, 1.0);
                            String formatDuration(Duration d) {
                              final m = d.inMinutes;
                              final s = d.inSeconds % 60;
                              return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white38,
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      value: value,
                                      onChanged: (v) => setState(() {
                                        _seekDragging = true;
                                        _seekValue = v;
                                      }),
                                      onChangeEnd: (v) {
                                        _player!.seek(
                                          Duration(
                                            milliseconds: (v * durMs).round(),
                                          ),
                                        );
                                        setState(() => _seekDragging = false);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${formatDuration(pos)} / ${formatDuration(dur)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

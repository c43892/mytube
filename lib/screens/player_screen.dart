import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../main.dart';
import '../services/audio_handler.dart';

class PlayerScreen extends StatefulWidget {
  final String filePath;
  final bool isAudio;
  const PlayerScreen({super.key, required this.filePath, required this.isAudio});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  late final Player _player;
  late final VideoController _controller;
  AppAudioHandler? _bgHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = Player();
    _controller = VideoController(_player);
    _initPlayback();
  }

  Future<void> _initPlayback() async {
    await _player.open(Media(widget.filePath));
    await _player.setVolume(0); // 前台画面静音，统一走后台音频链路

    if (!widget.isAudio) {
      final h = await ensureAudioHandler();
      _bgHandler = h;
      final title = File(widget.filePath).uri.pathSegments.last;
      await h.load(widget.filePath, title);
      await h.play();
      await _player.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _player.pause();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _syncVideoToBackgroundAudio();
    }
  }

  Future<void> _syncVideoToBackgroundAudio() async {
    try {
      final h = _bgHandler;
      if (h == null) return;
      final pos = h.rawPlayer.position;
      await _player.seek(pos);
      await _player.play();
      await _player.setVolume(0);
    } catch (_) {}
  }

  Future<void> _seekBoth(Duration position) async {
    await _player.seek(position);
    await _bgHandler?.seek(position);
  }

  Future<void> _pauseBoth() async {
    await _player.pause();
    await _bgHandler?.pause();
  }

  Future<void> _playBoth() async {
    await _bgHandler?.play();
    await _player.play();
    await _player.setVolume(0);
  }

  @override
  Widget build(BuildContext context) {
    final title = File(widget.filePath).uri.pathSegments.last;
    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: Column(
        children: [
          if (!widget.isAudio)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Video(controller: _controller),
            )
          else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Icon(Icons.audiotrack, size: 80),
            ),
          StreamBuilder<Duration>(
            stream: _player.stream.position,
            builder: (context, posSnap) {
              return StreamBuilder<Duration>(
                stream: _player.stream.duration,
                builder: (context, durSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  final dur = durSnap.data ?? const Duration(seconds: 1);
                  return Column(
                    children: [
                      Slider(
                        value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
                        max: dur.inMilliseconds.toDouble(),
                        onChanged: (v) => _seekBoth(Duration(milliseconds: v.toInt())),
                      ),
                      Text('${_fmt(pos)} / ${_fmt(dur)}'),
                    ],
                  );
                },
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _pauseBoth,
                icon: const Icon(Icons.pause),
              ),
              IconButton(
                onPressed: _playBoth,
                icon: const Icon(Icons.play_arrow),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

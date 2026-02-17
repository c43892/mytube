import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../main.dart';
import '../services/audio_handler.dart';
import 'home_screen.dart';

class PlayerScreen extends StatefulWidget {
  final String filePath;
  final bool isAudio;
  final String? author;
  const PlayerScreen({super.key, required this.filePath, required this.isAudio, this.author});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  late final Player _player;
  late final VideoController _controller;
  AppAudioHandler? _bgHandler;
  bool _handoffStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.filePath));
    if (!widget.isAudio) {
      _prepareBackgroundHandler();
    }
  }

  Future<void> _prepareBackgroundHandler() async {
    final h = await ensureAudioHandler();
    if (!mounted) return;
    _bgHandler = h;
    final title = File(widget.filePath).uri.pathSegments.last;
    await h.load(widget.filePath, title);
    debugPrint('[bg-handoff] prepared for $title');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handoffStarted = false;
      _syncForegroundFromBackground();
      return;
    }
    if (state == AppLifecycleState.paused && !widget.isAudio && !_handoffStarted) {
      _handoffStarted = true;
      _handoffToBackgroundAudio();
    }
  }

  Future<void> _syncForegroundFromBackground() async {
    try {
      final h = _bgHandler;
      if (h == null) return;
      final bgPos = h.rawPlayer.position;
      await h.pause();
      await _player.seek(bgPos);
      await _player.play();
      debugPrint('[bg-handoff] sync foreground to ${bgPos.inSeconds}s');
    } catch (e) {
      debugPrint('[bg-handoff] sync foreground failed: $e');
    }
  }

  Future<void> _handoffToBackgroundAudio() async {
    try {
      debugPrint('[bg-handoff] lifecycle paused, start handoff');
      final pos = _player.state.position;
      await _player.pause();

      final h = _bgHandler ?? await ensureAudioHandler();
      final title = File(widget.filePath).uri.pathSegments.last;
      await h.load(widget.filePath, title);
      await h.seek(pos);
      await h.play();

      debugPrint('[bg-handoff] handoff playing from ${pos.inSeconds}s');
    } catch (e) {
      debugPrint('[bg-handoff] failed: $e');
      _handoffStarted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = File(widget.filePath).uri.pathSegments.last;
    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: widget.isAudio
                    ? const Center(child: Icon(Icons.audiotrack, size: 80, color: Colors.white70))
                    : Video(controller: _controller),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if ((widget.author ?? '').trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen(initialQuery: widget.author)),
                  );
                },
                icon: const Icon(Icons.person_search, size: 18),
                label: Text(widget.author!),
              ),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: StreamBuilder<Duration>(
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
                          onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(pos), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            Text(_fmt(dur), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<bool>(
                          stream: _player.stream.playing,
                          builder: (context, playingSnap) {
                            final isPlaying = playingSnap.data ?? false;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilledButton.icon(
                                  onPressed: isPlaying ? _player.pause : _player.play,
                                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                                  label: Text(isPlaying ? 'Pause' : 'Play'),
                                ),
                              ],
                            );
                          },
                        )
                      ],
                    );
                  },
                );
              },
            ),
          ),
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

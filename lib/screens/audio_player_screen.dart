import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/audio_handler.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;
  const AudioPlayerScreen({super.key, required this.filePath});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  AppAudioHandler? _handler;

  @override
  void initState() {
    super.initState();
    _initAndPlay();
  }

  Future<void> _initAndPlay() async {
    final name = File(widget.filePath).uri.pathSegments.last;
    final handler = await ensureAudioHandler();
    if (!mounted) return;
    setState(() => _handler = handler);
    await handler.load(widget.filePath, name);
    await handler.play();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final title = File(widget.filePath).uri.pathSegments.last;
    final h = _handler;
    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: h == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<PlaybackState>(
              stream: h.playbackState,
              builder: (context, snap) {
                final state = snap.data;
                final playing = state?.playing ?? false;
                final total = h.rawPlayer.duration ?? const Duration(seconds: 1);
                final pos = state?.updatePosition ?? Duration.zero;

                return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.music_note, size: 96),
                const SizedBox(height: 20),
                Slider(
                  value: pos.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                  max: total.inMilliseconds.toDouble(),
                  onChanged: (v) => h.seek(Duration(milliseconds: v.toInt())),
                ),
                Text('${_fmt(pos)} / ${_fmt(total)}'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: playing ? h.pause : h.play,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    ),
                    IconButton(
                      onPressed: h.stop,
                      icon: const Icon(Icons.stop),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('锁屏/后台可继续播放（使用系统媒体通知）'),
              ],
            ),
          );
        },
      ),
    );
  }
}

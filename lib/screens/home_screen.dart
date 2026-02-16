import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import '../models/media_candidate.dart';
import '../services/download_service.dart';
import '../services/youtube_resolver.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _resolver = YoutubeResolver();
  final _downloader = DownloadService();
  final _searchController = TextEditingController();
  final ReceivePort _port = ReceivePort();

  bool _busy = false;
  String? _error;
  List<MediaCandidate> _videos = const [];

  String? _activeTaskId;
  String? _activeFilePath;
  String? _activeSourceUrl;
  String? _activeTitle;
  int _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) async {
      final String id = data[0] as String;
      final int status = data[1] as int;
      final int progress = data[2] as int;
      if (id != _activeTaskId) return;

      setState(() => _downloadProgress = progress);

      if (status == DownloadTaskStatus.complete.index && _activeFilePath != null && mounted) {
        await _downloader.markVideoPlayed(
          sourceUrl: _activeSourceUrl ?? '',
          filePath: _activeFilePath!,
          title: _activeTitle ?? 'video',
        );
        setState(() => _busy = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(filePath: _activeFilePath!, isAudio: false),
          ),
        );
      } else if (status == DownloadTaskStatus.failed.index || status == DownloadTaskStatus.canceled.index) {
        setState(() {
          _busy = false;
          _error = '下载失败/已取消，请重试';
        });
      }
    });

    _loadHomeVideos();
  }

  Future<void> _loadHomeVideos() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _resolver.fetchHomeVideos();
      setState(() => _videos = data);
    } catch (e) {
      setState(() => _error = '加载首页视频失败：$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _searchVideos() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      _loadHomeVideos();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _resolver.searchVideos(q);
      setState(() => _videos = data);
    } catch (e) {
      setState(() => _error = '搜索失败：$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _downloadAndPlay(MediaCandidate item) async {
    setState(() {
      _busy = true;
      _error = null;
      _downloadProgress = 0;
    });
    try {
      final cached = await _downloader.getCachedVideoPath(item.sourceUrl);
      if (cached != null && mounted) {
        await _downloader.markVideoPlayed(
          sourceUrl: item.sourceUrl,
          filePath: cached,
          title: item.title,
        );
        setState(() => _busy = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerScreen(filePath: cached, isAudio: false)),
        );
        return;
      }

      final resolved = await _resolver.resolveVideoForDownload(item.sourceUrl);
      final result = await _downloader.queueDownload(resolved);
      _activeTaskId = result.taskId;
      _activeFilePath = result.filePath;
      _activeSourceUrl = item.sourceUrl;
      _activeTitle = item.title;
    } on PlatformException catch (e) {
      setState(() {
        _error = '下载初始化失败：${e.message}';
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = '下载失败：$e';
        _busy = false;
      });
    }
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _port.close();
    _resolver.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube 视频列表'),
        actions: [
          IconButton(onPressed: _busy ? null : _loadHomeVideos, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _busy ? null : _searchVideos(),
                    decoration: const InputDecoration(
                      hintText: '搜索视频（自动过滤 Shorts）',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _searchVideos,
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_busy)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress / 100 : null),
                    const SizedBox(height: 6),
                    Text(_downloadProgress > 0 ? '下载中：$_downloadProgress%' : '加载中...'),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _videos.length,
                itemBuilder: (_, i) {
                  final v = _videos[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      title: Text(
                        v.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              v.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              v.duration == null ? '视频' : '时长 ${_fmt(v.duration!)}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      onTap: _busy ? null : () => _downloadAndPlay(v),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

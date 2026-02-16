import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import '../l10n/app_localizations.dart';
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
  bool _downloading = false;
  String? _downloadingForUrl;
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
        setState(() {
          _busy = false;
          _downloading = false;
          _downloadingForUrl = null;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(filePath: _activeFilePath!, isAudio: false),
          ),
        );
      } else if (status == DownloadTaskStatus.failed.index || status == DownloadTaskStatus.canceled.index) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _busy = false;
          _downloading = false;
          _downloadingForUrl = null;
          _error = l10n.downloadTaskFailed;
        });
      }
    });

    _loadHomeVideos();
  }

  Future<void> _loadHomeVideos({bool strongRandom = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _resolver.fetchHomeVideos(strongRandom: strongRandom);
      setState(() => _videos = data);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _error = l10n.loadHomeFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _searchVideos() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      _loadHomeVideos(strongRandom: true);
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
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _error = l10n.searchFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelActiveDownloadIfAny() async {
    final taskId = _activeTaskId;
    if (taskId == null) return;
    try {
      await _downloader.cancelTask(taskId);
      await _downloader.removeTask(taskId);
    } catch (_) {}
    _activeTaskId = null;
    _activeFilePath = null;
    _activeSourceUrl = null;
    _activeTitle = null;
  }

  Future<void> _downloadAndPlay(MediaCandidate item) async {
    if (_downloading && _activeSourceUrl == item.sourceUrl) return;

    if (_downloading && _activeTaskId != null && _activeSourceUrl != item.sourceUrl) {
      await _cancelActiveDownloadIfAny();
    }

    setState(() {
      _busy = true;
      _downloading = true;
      _downloadingForUrl = item.sourceUrl;
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
        setState(() {
          _busy = false;
          _downloading = false;
          _downloadingForUrl = null;
        });
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
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = l10n.downloadInitFailed(e.message ?? e.toString());
        _busy = false;
        _downloading = false;
        _downloadingForUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = l10n.downloadFailed(e.toString());
        _busy = false;
        _downloading = false;
        _downloadingForUrl = null;
      });
    }
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _port.close();
    if (_activeTaskId != null) {
      _downloader.cancelTask(_activeTaskId!).catchError((_) {});
    }
    _resolver.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            onPressed: (_busy && !_downloading) ? null : () => _loadHomeVideos(strongRandom: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => (_busy && !_downloading) ? null : _searchVideos(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.searchHint,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: (_busy && !_downloading) ? null : _searchVideos,
                    icon: const Icon(Icons.travel_explore),
                    label: Text(l10n.search),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_busy)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress / 100 : null),
                    ),
                    const SizedBox(height: 6),
                    Text(_downloadProgress > 0 ? l10n.downloadingProgress(_downloadProgress) : l10n.loading),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: _videos.isEmpty && !_busy
                  ? const Center(child: Text('No videos'))
                  : ListView.separated(
                      itemCount: _videos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final v = _videos[i];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _downloadAndPlay(v),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 112,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: SizedBox(
                                            width: 108,
                                            height: 62,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.network(
                                                  v.thumbnailUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: Theme.of(context).colorScheme.primaryContainer,
                                                    child: const Icon(Icons.play_circle_fill_rounded, size: 28),
                                                  ),
                                                ),
                                                Container(
                                                  color: const Color(0x22000000),
                                                  alignment: Alignment.bottomRight,
                                                  padding: const EdgeInsets.all(4),
                                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Center(
                                          child: Text(
                                            v.author,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                v.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                            if (_downloadingForUrl == v.sourceUrl)
                                              const Padding(
                                                padding: EdgeInsets.only(left: 6),
                                                child: SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            if (v.publishedAt != null)
                                              _metaChip(context, Icons.calendar_today, _relativeTime(v.publishedAt!)),
                                            _metaChip(context, Icons.schedule, v.duration == null ? l10n.video : _fmt(v.duration!)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _metaChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  String _relativeTime(DateTime publishedAt) {
    final now = DateTime.now();
    final diff = now.difference(publishedAt);
    if (diff.inDays < 1) return '今天';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}个月前';
    return '${(diff.inDays / 365).floor()}年前';
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

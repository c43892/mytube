import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import '../l10n/app_localizations.dart';
import '../models/media_candidate.dart';
import '../models/video_record.dart';
import '../services/download_service.dart';
import '../services/library_store.dart';
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
  final _store = LibraryStore();
  final _searchController = TextEditingController();
  final ReceivePort _port = ReceivePort();

  bool _busy = false;
  bool _downloading = false;
  String? _downloadingForUrl;
  String? _error;

  int _tabIndex = 0;
  List<MediaCandidate> _videos = const [];
  List<VideoRecord> _history = const [];
  List<VideoRecord> _favorites = const [];
  Set<String> _favoriteUrls = {};

  String? _activeTaskId;
  String? _activeFilePath;
  MediaCandidate? _activeItem;
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
        final item = _activeItem;
        if (item != null) {
          await _downloader.markVideoPlayed(sourceUrl: item.sourceUrl, filePath: _activeFilePath!, title: item.title);
          await _store.addHistory(item);
          await _reloadLibraryData();
        }

        setState(() {
          _busy = false;
          _downloading = false;
          _downloadingForUrl = null;
          _activeTaskId = null;
        });

        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(filePath: _activeFilePath!, isAudio: false)));
      } else if (status == DownloadTaskStatus.failed.index || status == DownloadTaskStatus.canceled.index) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _busy = false;
          _downloading = false;
          _downloadingForUrl = null;
          _activeTaskId = null;
          _error = l10n.downloadTaskFailed;
        });
      }
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _reloadLibraryData();
    await _loadHomeVideos();
  }

  Future<void> _reloadLibraryData() async {
    final history = await _store.loadHistory();
    final favorites = await _store.loadFavorites();
    if (!mounted) return;
    setState(() {
      _history = history;
      _favorites = favorites;
      _favoriteUrls = favorites.map((e) => e.media.sourceUrl).toSet();
    });
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
      _tabIndex = 0;
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
    _activeItem = null;
  }

  Future<void> _downloadAndPlay(MediaCandidate item) async {
    if (_downloading && _activeItem?.sourceUrl == item.sourceUrl) return;
    if (_downloading && _activeTaskId != null && _activeItem?.sourceUrl != item.sourceUrl) {
      await _cancelActiveDownloadIfAny();
    }

    setState(() {
      _busy = true;
      _downloading = true;
      _downloadingForUrl = item.sourceUrl;
      _error = null;
      _downloadProgress = 0;
      _activeItem = item;
    });

    try {
      final cached = await _downloader.getCachedVideoPath(item.sourceUrl);
      if (cached != null && mounted) {
        await _downloader.markVideoPlayed(sourceUrl: item.sourceUrl, filePath: cached, title: item.title);
        await _store.addHistory(item);
        await _reloadLibraryData();

        setState(() {
          _busy = false;
          _downloading = false;
          _downloadingForUrl = null;
        });

        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(filePath: cached, isAudio: false)));
        return;
      }

      final resolved = await _resolver.resolveVideoForDownload(item.sourceUrl);
      final result = await _downloader.queueDownload(resolved);
      _activeTaskId = result.taskId;
      _activeFilePath = result.filePath;
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

  Future<void> _toggleFavorite(MediaCandidate item) async {
    await _store.toggleFavorite(item);
    await _reloadLibraryData();
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
    final list = _tabIndex == 0
        ? _videos
        : _tabIndex == 1
            ? _history.map((e) => e.media).toList()
            : _favorites.map((e) => e.media).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            if (_tabIndex == 0) _buildSearchBar(l10n),
            if (_tabIndex == 0) const SizedBox(height: 10),
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
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: list.isEmpty && !_busy
                  ? Center(child: Text(_tabIndex == 0 ? 'No videos' : _tabIndex == 1 ? 'No history yet' : 'No favorites yet'))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildVideoCard(list[i], l10n),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shuffle_rounded), label: '默认'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: '历史'),
          NavigationDestination(icon: Icon(Icons.star_rounded), label: '收藏'),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => (_busy && !_downloading) ? null : _searchVideos(),
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.searchHint, isDense: true),
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
    );
  }

  Widget _buildVideoCard(MediaCandidate v, AppLocalizations l10n) {
    final isFav = _favoriteUrls.contains(v.sourceUrl);
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
                          child: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: isFav ? '取消收藏' : '收藏',
                          onPressed: () => _toggleFavorite(v),
                          icon: Icon(isFav ? Icons.star_rounded : Icons.star_border_rounded, color: isFav ? Colors.amber : Colors.black54),
                        ),
                        if (_downloadingForUrl == v.sourceUrl)
                          const Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (v.publishedAt != null) _metaChip(context, Icons.calendar_today, _relativeTime(v.publishedAt!)),
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

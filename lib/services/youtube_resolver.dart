import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/media_candidate.dart';

class YoutubeResolver {
  final YoutubeExplode _yt = YoutubeExplode();

  List<MediaCandidate> _homeCache = const [];
  DateTime? _homeCacheAt;
  static const Duration _homeCacheTtl = Duration(minutes: 30);

  int _failCount = 0;
  DateTime? _backoffUntil;

  static const List<String> _fallbackQueries = [
    'YouTube Trending',
    '热门 视频',
    '今日热门',
  ];

  Duration? _parseDuration(dynamic raw) {
    if (raw == null) return null;
    if (raw is Duration) return raw;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.length == 3) return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    if (parts.length == 2) return Duration(minutes: parts[0], seconds: parts[1]);
    if (parts.length == 1) return Duration(seconds: parts[0]);
    return null;
  }

  String _parseAuthor(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    return s.isEmpty ? 'Unknown Channel' : s;
  }

  bool _isNormalVideo(dynamic v) {
    final title = (v.title?.toString() ?? '').toLowerCase();
    final url = 'https://www.youtube.com/watch?v=${v.id.value}'.toLowerCase();
    final d = _parseDuration(v.duration);

    if (title.contains('#shorts') || title.contains(' shorts') || title.startsWith('shorts')) return false;
    if (url.contains('/shorts/')) return false;
    if (d != null && d.inSeconds <= 60) return false;
    if (d == null) return false;
    return true;
  }

  DateTime? _parsePublishedAt(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _thumbById(String id) => 'https://i.ytimg.com/vi/$id/hqdefault.jpg';

  String _parseThumb(dynamic thumbs, String id) {
    try {
      final hq = thumbs?.highResUrl?.toString();
      if (hq != null && hq.isNotEmpty) return hq;
      final max = thumbs?.maxResUrl?.toString();
      if (max != null && max.isNotEmpty) return max;
      final std = thumbs?.standardResUrl?.toString();
      if (std != null && std.isNotEmpty) return std;
      final med = thumbs?.mediumResUrl?.toString();
      if (med != null && med.isNotEmpty) return med;
    } catch (_) {}
    return _thumbById(id);
  }

  MediaCandidate _toCandidate(dynamic v) {
    final id = v.id.value.toString();
    final url = 'https://www.youtube.com/watch?v=$id';
    return MediaCandidate(
      title: v.title.toString(),
      author: _parseAuthor(v.author),
      publishedAt: _parsePublishedAt(v.uploadDate),
      thumbnailUrl: _parseThumb(v.thumbnails, id),
      duration: _parseDuration(v.duration),
      sourceUrl: url,
      streamUrl: '',
      isAudio: false,
      fileExt: 'mp4',
    );
  }

  bool _inBackoff() => _backoffUntil != null && DateTime.now().isBefore(_backoffUntil!);

  void _markFailure() {
    _failCount = (_failCount + 1).clamp(1, 6);
    const seconds = [5, 15, 30, 60, 180, 300];
    _backoffUntil = DateTime.now().add(Duration(seconds: seconds[_failCount - 1]));
  }

  void _markSuccess() {
    _failCount = 0;
    _backoffUntil = null;
  }

  Future<Iterable<dynamic>> _searchWithRetry(String q, {int retries = 2}) async {
    Object? last;
    for (int i = 0; i <= retries; i++) {
      try {
        return await _yt.search.search(q, filter: TypeFilters.video);
      } catch (e) {
        last = e;
        if (i < retries) {
          await Future.delayed(Duration(seconds: 1 << i));
        }
      }
    }
    throw last ?? Exception('search failed');
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<File> _keywordCacheFile() async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}${Platform.pathSeparator}daily_hot_queries.json');
  }

  List<String> _parseRssTitles(String xml) {
    final reg = RegExp(r'<title(?:[^>]*)>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?<\/title>', dotAll: true, caseSensitive: false);
    final out = <String>[];
    for (final m in reg.allMatches(xml)) {
      final t = (m.group(1) ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (t.isEmpty) continue;
      if (t.toLowerCase().contains('daily search trends')) continue;
      if (t.length < 2) continue;
      out.add(t);
    }
    return out;
  }

  Future<List<String>> _loadDailyHotQueries() async {
    final today = _dayKey(DateTime.now());
    final f = await _keywordCacheFile();

    try {
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is Map && raw['day'] == today && raw['queries'] is List) {
          final q = (raw['queries'] as List).map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
          if (q.isNotEmpty) return q;
        }
      }
    } catch (_) {}

    final client = HttpClient();
    final trendUrls = [
      'https://trends.google.com/trending/rss?geo=US',
      'https://trends.google.com/trending/rss?geo=TW',
      'https://trends.google.com/trending/rss?geo=JP',
    ];

    final all = <String>[];
    for (final u in trendUrls) {
      try {
        final req = await client.getUrl(Uri.parse(u));
        req.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0');
        final resp = await req.close();
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final xml = await utf8.decoder.bind(resp).join();
          all.addAll(_parseRssTitles(xml));
        }
      } catch (_) {}
    }
    client.close(force: true);

    final dedup = <String>{..._fallbackQueries};
    for (final t in all.take(25)) {
      dedup.add(t);
    }
    final queries = dedup.take(12).toList();

    try {
      await f.writeAsString(jsonEncode({'day': today, 'queries': queries}), flush: true);
    } catch (_) {}

    return queries.isEmpty ? _fallbackQueries : queries;
  }

  Future<List<MediaCandidate>> fetchHomeVideos({int max = 20, bool strongRandom = false}) async {
    final now = DateTime.now();
    if (_homeCacheAt != null && now.difference(_homeCacheAt!) < _homeCacheTtl && _homeCache.isNotEmpty) {
      return _homeCache.take(max).toList();
    }

    if (_inBackoff()) {
      if (_homeCache.isNotEmpty) return _homeCache.take(max).toList();
      throw Exception('请求过于频繁，稍后再试');
    }

    try {
      final queries = await _loadDailyHotQueries();
      final Map<String, MediaCandidate> dedup = {};
      for (final q in queries) {
        final list = await _searchWithRetry(q);
        for (final v in list.where(_isNormalVideo)) {
          final id = v.id.value.toString();
          if (dedup.containsKey(id)) continue;
          dedup[id] = _toCandidate(v);
          if (dedup.length >= max) break;
        }
        if (dedup.length >= max) break;
      }

      final result = dedup.values.take(max).toList();
      _homeCache = result;
      _homeCacheAt = now;
      _markSuccess();
      return result;
    } catch (e) {
      _markFailure();
      if (_homeCache.isNotEmpty) return _homeCache.take(max).toList();
      rethrow;
    }
  }

  Future<List<MediaCandidate>> searchVideos(String keyword, {int max = 20}) async {
    if (_inBackoff()) {
      throw Exception('搜索请求过于频繁，请稍后再试');
    }
    try {
      final list = await _searchWithRetry(keyword);
      _markSuccess();
      return list.where(_isNormalVideo).take(max).map(_toCandidate).toList();
    } catch (_) {
      _markFailure();
      rethrow;
    }
  }

  Future<MediaCandidate> resolveVideoForDownload(String youtubeUrl) async {
    final video = await _yt.videos.get(youtubeUrl);
    final manifest = await _yt.videos.streamsClient.getManifest(video.id);
    final muxedStreams = manifest.muxed.toList();

    final muxed = (muxedStreams.where((s) => s.container.name.toLowerCase() == 'mp4').toList()
          ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond)))
        .firstOrNull ??
        muxedStreams.withHighestBitrate();

    return MediaCandidate(
      title: video.title,
      author: _parseAuthor(video.author),
      publishedAt: video.uploadDate,
      thumbnailUrl: _thumbById(video.id.value),
      duration: video.duration,
      sourceUrl: youtubeUrl,
      streamUrl: muxed.url.toString(),
      isAudio: false,
      fileExt: muxed.container.name,
    );
  }

  void dispose() => _yt.close();
}

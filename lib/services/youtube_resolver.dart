import 'dart:math';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/media_candidate.dart';

class YoutubeResolver {
  final YoutubeExplode _yt = YoutubeExplode();
  final Random _random = Random();
  final Map<String, DateTime> _recentShown = {};

  static const Duration _recentWindow = Duration(hours: 2);

  static const List<String> _queryPool = [
    'YouTube Trending',
    'Viral videos',
    'Top music video',
    'Gaming highlights',
    'Tech review',
    'Travel vlog',
    'Movie trailer',
    'Live performance',
    '热门 视频',
    '今日热门',
    '中文 热门 音乐',
    '搞笑 视频',
    '日语 音乐',
    'K-pop MV',
    'Spanish pop music',
    'French songs',
    'Documentary',
    'Football highlights',
    'Basketball highlights',
    'Science explained',
  ];

  Duration? _parseDuration(dynamic raw) {
    if (raw == null) return null;
    if (raw is Duration) return raw;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    }
    if (parts.length == 1) {
      return Duration(seconds: parts[0]);
    }
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

  List<T> _pickRandom<T>(List<T> list, int n) {
    final copy = List<T>.from(list)..shuffle(_random);
    final count = n.clamp(0, copy.length) as int;
    return copy.take(count).toList();
  }

  void _pruneRecent() {
    final now = DateTime.now();
    final toRemove = <String>[];
    _recentShown.forEach((id, at) {
      if (now.difference(at) > _recentWindow) toRemove.add(id);
    });
    for (final id in toRemove) {
      _recentShown.remove(id);
    }
  }

  Future<List<MediaCandidate>> fetchHomeVideos({int max = 20, bool strongRandom = false}) async {
    _pruneRecent();

    final queryCount = strongRandom ? 6 : 4;
    final sampledQueries = _pickRandom(_queryPool, queryCount);
    final Map<String, MediaCandidate> dedup = {};
    final List<MediaCandidate> fresh = [];
    final List<MediaCandidate> recent = [];

    for (final q in sampledQueries) {
      final list = await _yt.search.search(q, filter: TypeFilters.video);
      final filtered = list.where(_isNormalVideo).take(30).toList();
      final picked = _pickRandom(filtered, strongRandom ? 8 : 6);
      for (final v in picked) {
        final id = v.id.value.toString();
        if (dedup.containsKey(id)) continue;
        final candidate = _toCandidate(v);
        dedup[id] = candidate;
        if (_recentShown.containsKey(id)) {
          recent.add(candidate);
        } else {
          fresh.add(candidate);
        }
      }
    }

    final ordered = <MediaCandidate>[...fresh, ...recent];

    if (ordered.length < max) {
      final fallback = await _yt.search.search('YouTube Trending', filter: TypeFilters.video);
      for (final v in fallback.where(_isNormalVideo)) {
        final id = v.id.value.toString();
        if (dedup.containsKey(id)) continue;
        final candidate = _toCandidate(v);
        dedup[id] = candidate;
        ordered.add(candidate);
        if (ordered.length >= max) break;
      }
    }

    final finalList = ordered.take(max).toList();
    final now = DateTime.now();
    for (final c in finalList) {
      final id = c.sourceUrl.split('v=').last;
      _recentShown[id] = now;
    }
    return finalList;
  }

  Future<List<MediaCandidate>> searchVideos(String keyword, {int max = 20}) async {
    final list = await _yt.search.search(keyword, filter: TypeFilters.video);
    return list.where(_isNormalVideo).take(max).map(_toCandidate).toList();
  }

  Future<MediaCandidate> resolveVideoForDownload(String youtubeUrl) async {
    final video = await _yt.videos.get(youtubeUrl);
    final manifest = await _yt.videos.streamsClient.getManifest(video.id);
    final muxedStreams = manifest.muxed.toList();

    final muxed = (muxedStreams
            .where((s) => s.container.name.toLowerCase() == 'mp4')
            .toList()
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

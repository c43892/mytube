import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/media_candidate.dart';

class YoutubeResolver {
  final YoutubeExplode _yt = YoutubeExplode();

  List<MediaCandidate> _homeCache = const [];
  DateTime? _homeCacheAt;
  static const Duration _homeCacheTtl = Duration(minutes: 30);

  static const List<String> _stableQueries = [
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

  Future<List<MediaCandidate>> fetchHomeVideos({int max = 20, bool strongRandom = false}) async {
    final now = DateTime.now();
    if (_homeCacheAt != null && now.difference(_homeCacheAt!) < _homeCacheTtl && _homeCache.isNotEmpty) {
      return _homeCache.take(max).toList();
    }

    final Map<String, MediaCandidate> dedup = {};
    for (final q in _stableQueries) {
      final list = await _yt.search.search(q, filter: TypeFilters.video);
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
    return result;
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

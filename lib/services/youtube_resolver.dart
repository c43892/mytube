import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/media_candidate.dart';

class YoutubeResolver {
  final YoutubeExplode _yt = YoutubeExplode();

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

  MediaCandidate _toCandidate(dynamic v) {
    final id = v.id.value.toString();
    final url = 'https://www.youtube.com/watch?v=$id';
    return MediaCandidate(
      title: v.title.toString(),
      author: _parseAuthor(v.author),
      duration: _parseDuration(v.duration),
      sourceUrl: url,
      streamUrl: '',
      isAudio: false,
      fileExt: 'mp4',
    );
  }

  Future<List<MediaCandidate>> fetchHomeVideos({int max = 20}) async {
    final queries = ['热门 视频', 'YouTube Trending', '今日热门'];
    final Map<String, MediaCandidate> dedup = {};

    for (final q in queries) {
      final list = await _yt.search.search(q, filter: TypeFilters.video);
      for (final v in list.where(_isNormalVideo)) {
        final id = v.id.value.toString();
        dedup[id] = _toCandidate(v);
        if (dedup.length >= max) break;
      }
      if (dedup.length >= max) break;
    }

    return dedup.values.take(max).toList();
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
      duration: video.duration,
      sourceUrl: youtubeUrl,
      streamUrl: muxed.url.toString(),
      isAudio: false,
      fileExt: muxed.container.name,
    );
  }

  void dispose() => _yt.close();
}

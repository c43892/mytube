import 'media_candidate.dart';

class VideoRecord {
  final MediaCandidate media;
  final DateTime updatedAt;

  const VideoRecord({required this.media, required this.updatedAt});

  Map<String, dynamic> toJson() => {
        'title': media.title,
        'author': media.author,
        'publishedAt': media.publishedAt?.toIso8601String(),
        'thumbnailUrl': media.thumbnailUrl,
        'durationSec': media.duration?.inSeconds,
        'sourceUrl': media.sourceUrl,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static VideoRecord fromJson(Map<String, dynamic> json) {
    final durationSec = json['durationSec'] is int ? json['durationSec'] as int : int.tryParse('${json['durationSec']}');
    return VideoRecord(
      media: MediaCandidate(
        title: '${json['title'] ?? ''}',
        author: '${json['author'] ?? ''}',
        publishedAt: DateTime.tryParse('${json['publishedAt'] ?? ''}'),
        thumbnailUrl: '${json['thumbnailUrl'] ?? ''}',
        duration: durationSec == null ? null : Duration(seconds: durationSec),
        sourceUrl: '${json['sourceUrl'] ?? ''}',
        streamUrl: '',
        isAudio: false,
        fileExt: 'mp4',
      ),
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class MediaCandidate {
  final String title;
  final String author;
  final DateTime? publishedAt;
  final String thumbnailUrl;
  final Duration? duration;
  final String sourceUrl;
  final String streamUrl;
  final bool isAudio;
  final String fileExt;

  const MediaCandidate({
    required this.title,
    required this.author,
    required this.publishedAt,
    required this.thumbnailUrl,
    required this.sourceUrl,
    required this.streamUrl,
    required this.isAudio,
    required this.fileExt,
    this.duration,
  });
}

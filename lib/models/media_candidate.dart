class MediaCandidate {
  final String title;
  final String author;
  final String publishedText;
  final String thumbnailUrl;
  final Duration? duration;
  final String sourceUrl;
  final String streamUrl;
  final bool isAudio;
  final String fileExt;

  const MediaCandidate({
    required this.title,
    required this.author,
    required this.publishedText,
    required this.thumbnailUrl,
    required this.sourceUrl,
    required this.streamUrl,
    required this.isAudio,
    required this.fileExt,
    this.duration,
  });
}

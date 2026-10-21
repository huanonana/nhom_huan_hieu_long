class StayImage {
  const StayImage(
    this.file,
    this.caption,
    this.author,
    this.source, {
    required this.verified,
    required this.sourceNote,
  });
  final String file, caption, author, source;
  final bool verified;
  final String sourceNote;
  String get asset => file;
}

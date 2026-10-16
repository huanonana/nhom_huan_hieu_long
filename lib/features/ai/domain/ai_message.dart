enum AiMessageRole { user, assistant }

class AiMessage {
  AiMessage({required this.role, required this.content, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  final AiMessageRole role;
  final String content;
  final DateTime timestamp;
}

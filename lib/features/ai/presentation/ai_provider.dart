import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService(
    apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'),
  );
  ref.onDispose(service.close);
  return service;
});

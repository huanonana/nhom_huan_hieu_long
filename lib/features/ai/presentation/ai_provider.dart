import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  const webProxy = String.fromEnvironment('AI_PROXY_WEB');
  const androidProxy = String.fromEnvironment('AI_PROXY_ANDROID');
  final proxy = kIsWeb
      ? webProxy
      : defaultTargetPlatform == TargetPlatform.android
      ? androidProxy
      : '';
  final service = AiService(apiKey: '', proxyBaseUrl: proxy);
  ref.onDispose(service.close);
  return service;
});

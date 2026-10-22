import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/state/demo_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app runs fully offline with device-local demo data.
  final container = await DemoStorage.device().load();
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Homestay HHL',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    scrollBehavior: AppScrollBehavior(),
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: ref.watch(routerProvider),
  );
}

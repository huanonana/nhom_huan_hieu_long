import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/booking/data/demo_booking_repository.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/booking/presentation/firestore_repository_provider.dart';
import 'app_state.dart';

final storageNoticeProvider = StateProvider<String?>((ref) => null);

// Demo convenience only; real bookings belong in the server database.
class DemoStorage {
  DemoStorage({required this.read, required this.write});
  factory DemoStorage.device() {
    final prefs = SharedPreferencesAsync();
    return DemoStorage(
      read: () => prefs.getString('hhl_demo_v1'),
      write: (value) => prefs.setString('hhl_demo_v1', value),
    );
  }
  final Future<String?> Function() read;
  final Future<void> Function(String) write;
  Future<void> _pending = Future.value();
  Future<void> get settled => _pending;

  Future<ProviderContainer> load({bool firebaseAuth = false}) async {
    var repository = DemoBookingRepository();
    var favorites = <String>{};
    String? notice;
    var canSave = true;
    try {
      final raw = await read();
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        repository = DemoBookingRepository.fromJson(data['repository']);
        favorites = Set<String>.from(data['favorites']);
      }
    } catch (_) {
      canSave = false; // Preserve unreadable data instead of overwriting it.
      notice =
          'Không đọc được dữ liệu đã lưu. Phiên này chỉ lưu tạm; dữ liệu cũ được giữ nguyên.';
    }
    if (canSave) repository.ensureRevenueDemoBookings();
    final container = ProviderContainer(
      overrides: [
        authModeProvider.overrideWithValue(firebaseAuth),
        useFirebaseBackendProvider.overrideWithValue(firebaseAuth),
        repositoryProvider.overrideWithValue(repository),
        favoritesProvider.overrideWith((ref) => favorites),
      ],
    );
    container.read(storageNoticeProvider.notifier).state = notice;
    String? previous;
    void save() {
      if (!canSave) return;
      final encoded = jsonEncode({
        'repository': repository.toJson(),
        'favorites': container.read(favoritesProvider).toList(),
      });
      if (encoded == previous) return;
      previous = encoded;
      _pending = _pending.then((_) async {
        try {
          await write(encoded);
          container.read(storageNoticeProvider.notifier).state = null;
        } catch (_) {
          previous = null;
          container.read(storageNoticeProvider.notifier).state =
              'Chưa lưu được thay đổi trên máy. Giữ app mở và thử thao tác lại.';
        }
      });
    }

    container.listen(changesProvider, (_, _) => save());
    container.listen(favoritesProvider, (_, _) => save());
    save();
    return container;
  }
}

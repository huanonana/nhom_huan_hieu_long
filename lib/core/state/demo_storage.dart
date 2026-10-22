import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/booking/data/demo_booking_repository.dart';
import '../../features/auth/data/demo_auth_repository.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/dashboard/domain/finance_entry.dart';
import '../../features/dashboard/domain/staff_shift.dart';
import '../../features/dashboard/domain/staff_member.dart';
import 'app_state.dart';

final storageNoticeProvider = StateProvider<String?>((ref) => null);

// Offline demo storage. All changes stay on this device and sync across tabs.
class DemoStorage {
  DemoStorage({
    required this.read,
    required this.write,
    this.readAuth,
    this.writeAuth,
    this.syncInterval,
  });
  factory DemoStorage.device() {
    final prefs = SharedPreferencesAsync();
    return DemoStorage(
      read: () => prefs.getString('hhl_demo_v1'),
      write: (value) => prefs.setString('hhl_demo_v1', value),
      readAuth: () => prefs.getString('hhl_auth_v1'),
      writeAuth: (value) => prefs.setString('hhl_auth_v1', value),
      syncInterval: const Duration(seconds: 2),
    );
  }
  final Future<String?> Function() read;
  final Future<void> Function(String) write;
  final Future<String?> Function()? readAuth;
  final Future<void> Function(String)? writeAuth;
  final Duration? syncInterval;
  Future<void> _pending = Future.value();
  Future<void> _authPending = Future.value();
  final List<Timer> _syncTimers = [];
  Future<void> get settled => Future.wait([_pending, _authPending]);

  void dispose() {
    for (final timer in _syncTimers) {
      timer.cancel();
    }
    _syncTimers.clear();
  }

  Future<ProviderContainer> load() async {
    var repository = DemoBookingRepository();
    var favorites = <String>{};
    var recentHomestays = <String>[];
    var financeEntries = <FinanceEntry>[];
    var staffShifts = <StaffShift>[];
    var staffMembers = <StaffMember>[];
    String? notice;
    var canSave = true;
    final authRepository = DemoAuthRepository.instance;
    var canSaveAuth = true;
    if (readAuth != null) {
      try {
        authRepository.restoreSnapshot(await readAuth!());
      } catch (_) {
        canSaveAuth = false;
        notice =
            'Không đọc được phiên tài khoản đã lưu. Dữ liệu tài khoản cũ được giữ nguyên.';
      }
    }
    String? lastKnownSnapshot;
    try {
      final raw = await read();
      lastKnownSnapshot = raw;
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        repository = DemoBookingRepository.fromJson(data['repository']);
        favorites = Set<String>.from(data['favorites'] ?? const <String>[]);
        recentHomestays = List<String>.from(
          data['recentHomestays'] ?? const <String>[],
        );
        financeEntries = (data['financeEntries'] as List<dynamic>? ?? const [])
            .map(
              (entry) => FinanceEntry.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
        staffShifts = (data['staffShifts'] as List<dynamic>? ?? const [])
            .map(
              (entry) =>
                  StaffShift.fromJson(Map<String, dynamic>.from(entry as Map)),
            )
            .toList();
        staffMembers = (data['staffMembers'] as List<dynamic>? ?? const [])
            .map(
              (entry) =>
                  StaffMember.fromJson(Map<String, dynamic>.from(entry as Map)),
            )
            .toList();
        if (staffMembers.isEmpty && staffShifts.isNotEmpty) {
          final known = <String>{};
          for (final shift in staffShifts) {
            final key = shift.staffName.trim().toLowerCase();
            if (key.isEmpty || !known.add(key)) continue;
            staffMembers.add(
              StaffMember(
                id: shift.staffId.isNotEmpty
                    ? shift.staffId
                    : 'staff-migrated-${known.length}',
                name: shift.staffName,
                role: shift.role,
                phone: '',
                hourlyRate: shift.hourlyRate,
              ),
            );
          }
        }
        final staffIdByName = {
          for (final member in staffMembers)
            member.name.trim().toLowerCase(): member.id,
        };
        staffShifts = staffShifts.map((shift) {
          if (shift.staffId.isNotEmpty) return shift;
          final id = staffIdByName[shift.staffName.trim().toLowerCase()];
          return id == null ? shift : shift.withStaffId(id);
        }).toList();
      }
    } catch (_) {
      canSave = false; // Preserve unreadable data instead of overwriting it.
      notice =
          'Không đọc được dữ liệu đã lưu. Phiên này chỉ lưu tạm; dữ liệu cũ được giữ nguyên.';
    }
    if (canSave) repository.ensureRevenueDemoBookings();
    final container = ProviderContainer(
      overrides: [
        authModeProvider.overrideWithValue(false),
        roleProvider.overrideWith(
          (ref) => authRepository.signedInUser?.role == AppUserRole.host
              ? DemoRole.host
              : DemoRole.guest,
        ),
        authRepositoryProvider.overrideWithValue(authRepository),
        repositoryProvider.overrideWithValue(repository),
        favoritesProvider.overrideWith((ref) => favorites),
        recentHomestaysProvider.overrideWith((ref) => recentHomestays),
        financeEntriesProvider.overrideWith((ref) => financeEntries),
        staffShiftsProvider.overrideWith((ref) => staffShifts),
        staffMembersProvider.overrideWith((ref) => staffMembers),
      ],
    );
    container.read(storageNoticeProvider.notifier).state = notice;
    if (writeAuth != null && canSaveAuth) {
      authRepository.setPersistence((snapshot) async {
        _authPending = _authPending.then((_) async {
          try {
            await writeAuth!(snapshot);
            container.read(storageNoticeProvider.notifier).state = null;
          } catch (_) {
            container.read(storageNoticeProvider.notifier).state =
                'Chưa lưu được tài khoản trên thiết bị. Hãy thử lại sau.';
          }
        });
        await _authPending;
      });
    } else {
      authRepository.setPersistence(null);
    }
    String? previous = lastKnownSnapshot;
    var saving = false;
    var syncing = false;
    void save() {
      if (!canSave || syncing) return;
      final encoded = jsonEncode({
        'repository': repository.toJson(),
        'favorites': container.read(favoritesProvider).toList(),
        'recentHomestays': container.read(recentHomestaysProvider),
        'financeEntries': container
            .read(financeEntriesProvider)
            .map((entry) => entry.toJson())
            .toList(),
        'staffShifts': container
            .read(staffShiftsProvider)
            .map((shift) => shift.toJson())
            .toList(),
        'staffMembers': container
            .read(staffMembersProvider)
            .map((member) => member.toJson())
            .toList(),
      });
      if (encoded == previous) return;
      previous = encoded;
      lastKnownSnapshot = encoded;
      _pending = _pending.then((_) async {
        saving = true;
        try {
          await write(encoded);
          container.read(storageNoticeProvider.notifier).state = null;
        } catch (_) {
          previous = null;
          container.read(storageNoticeProvider.notifier).state =
              'Chưa lưu được thay đổi trên máy. Giữ app mở và thử thao tác lại.';
        } finally {
          saving = false;
        }
      });
    }

    container.listen(changesProvider, (_, _) => save());
    container.listen(favoritesProvider, (_, _) => save());
    container.listen(recentHomestaysProvider, (_, _) => save());
    container.listen(financeEntriesProvider, (_, _) => save());
    container.listen(staffShiftsProvider, (_, _) => save());
    container.listen(staffMembersProvider, (_, _) => save());
    if (syncInterval case final interval?) {
      final syncTimer = Timer.periodic(interval, (_) async {
        if (saving || syncing) return;
        syncing = true;
        try {
          final raw = await read();
          if (raw == null || raw == lastKnownSnapshot) return;
          final data = jsonDecode(raw) as Map<String, dynamic>;
          repository.restoreFromJson(
            Map<String, dynamic>.from(data['repository'] as Map),
          );
          lastKnownSnapshot = raw;
          previous = raw;
          container.read(favoritesProvider.notifier).state = Set<String>.from(
            data['favorites'] ?? const [],
          );
          container.read(recentHomestaysProvider.notifier).state =
              List<String>.from(data['recentHomestays'] ?? const []);
          container
              .read(financeEntriesProvider.notifier)
              .state = (data['financeEntries'] as List<dynamic>? ?? const [])
              .map(
                (entry) => FinanceEntry.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList();
          container
              .read(staffShiftsProvider.notifier)
              .state = (data['staffShifts'] as List<dynamic>? ?? const [])
              .map(
                (entry) => StaffShift.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList();
          container
              .read(staffMembersProvider.notifier)
              .state = (data['staffMembers'] as List<dynamic>? ?? const [])
              .map(
                (entry) => StaffMember.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList();
          container.read(changesProvider.notifier).refreshFromStorage();
        } catch (_) {
          // Ignore a partial external write and keep the active data intact.
        } finally {
          syncing = false;
        }
      });
      _syncTimers.add(syncTimer);
    }
    save();
    return container;
  }
}

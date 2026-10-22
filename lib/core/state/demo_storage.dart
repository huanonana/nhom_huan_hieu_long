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
    final favoritesByUser = <String, Set<String>>{};
    final recentHomestaysByUser = <String, List<String>>{};
    var legacyFavorites = <String>{};
    var legacyRecentHomestays = <String>[];
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
        legacyFavorites = Set<String>.from(
          data['favorites'] ?? const <String>[],
        );
        legacyRecentHomestays = List<String>.from(
          data['recentHomestays'] ?? const <String>[],
        );
        final savedFavoritesByUser = Map<String, dynamic>.from(
          data['favoritesByUser'] as Map? ?? const {},
        );
        for (final entry in savedFavoritesByUser.entries) {
          favoritesByUser[entry.key] = Set<String>.from(entry.value as List);
        }
        final savedRecentByUser = Map<String, dynamic>.from(
          data['recentHomestaysByUser'] as Map? ?? const {},
        );
        for (final entry in savedRecentByUser.entries) {
          recentHomestaysByUser[entry.key] = List<String>.from(
            entry.value as List,
          );
        }
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
    var seededGuestHistory = false;
    var seededDemoFinance = false;
    var seededDemoAccounts = false;
    if (readAuth != null && canSaveAuth) {
      seededDemoAccounts = authRepository.ensureDemoAccounts();
    }
    if (canSave) {
      repository.ensureRevenueDemoBookings();
      if (readAuth != null && canSaveAuth) {
        final beforeFinance = financeEntries.map((entry) => entry.id).toSet();
        for (final entry in _demoFinanceEntries) {
          if (!beforeFinance.contains(entry.id)) financeEntries.add(entry);
        }
        seededDemoFinance = financeEntries.length != beforeFinance.length;
        final demoGuest = authRepository.userByEmail(
          DemoAuthRepository.demoGuestEmail,
        );
        if (demoGuest != null && demoGuest.role == AppUserRole.guest) {
          final before = jsonEncode(repository.toJson());
          repository.ensureGuestDemoHistory(
            guestId: demoGuest.uid,
            guestName: demoGuest.displayName.isEmpty
                ? 'Khách demo HHL Stay'
                : demoGuest.displayName,
          );
          seededGuestHistory = before != jsonEncode(repository.toJson());
        }
      }
    }
    var activeUserId = authRepository.signedInUser?.uid;
    if (activeUserId != null) {
      favorites = favoritesByUser[activeUserId] ?? legacyFavorites;
      recentHomestays =
          recentHomestaysByUser[activeUserId] ?? legacyRecentHomestays;
      favoritesByUser.putIfAbsent(activeUserId, () => {...favorites});
      recentHomestaysByUser.putIfAbsent(
        activeUserId,
        () => [...recentHomestays],
      );
      legacyFavorites = {};
      legacyRecentHomestays = [];
    } else {
      // Keep pre-account preferences available for one-time migration at login.
      favorites = readAuth == null ? legacyFavorites : {};
      recentHomestays = readAuth == null ? legacyRecentHomestays : <String>[];
    }
    if (seededGuestHistory || seededDemoFinance) lastKnownSnapshot = null;
    final container = ProviderContainer(
      overrides: [
        // The real device app always uses account authentication. The
        // provider's default remains available only to isolated widget tests.
        authModeProvider.overrideWithValue(true),
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
            _setStorageNotice(container, null);
          } catch (_) {
            _setStorageNotice(
              container,
              'Chưa lưu được tài khoản trên thiết bị. Hãy thử lại sau.',
            );
          }
        });
        await _authPending;
      });
    } else {
      authRepository.setPersistence(null);
    }
    if (seededDemoAccounts && writeAuth != null && canSaveAuth) {
      await authRepository.persistSnapshot();
    }
    String? previous = lastKnownSnapshot;
    var saving = false;
    var syncing = false;
    void save() {
      if (!canSave || syncing) return;
      if (activeUserId != null) {
        favoritesByUser[activeUserId!] = {...container.read(favoritesProvider)};
        recentHomestaysByUser[activeUserId!] = [
          ...container.read(recentHomestaysProvider),
        ];
        legacyFavorites = {};
        legacyRecentHomestays = [];
      } else if (readAuth == null) {
        legacyFavorites = {...container.read(favoritesProvider)};
        legacyRecentHomestays = [...container.read(recentHomestaysProvider)];
      }
      final encoded = jsonEncode({
        'repository': repository.toJson(),
        // Keep legacy fields for older builds; account maps are authoritative.
        'favorites': legacyFavorites.toList(),
        'recentHomestays': legacyRecentHomestays,
        'favoritesByUser': {
          for (final entry in favoritesByUser.entries)
            entry.key: entry.value.toList(),
        },
        'recentHomestaysByUser': recentHomestaysByUser,
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
    container.listen(currentUserProvider, (_, next) {
      if (!next.hasValue) return;
      final nextUserId = next.valueOrNull?.uid;
      if (nextUserId == activeUserId) return;
      if (activeUserId != null) {
        favoritesByUser[activeUserId!] = {...container.read(favoritesProvider)};
        recentHomestaysByUser[activeUserId!] = [
          ...container.read(recentHomestaysProvider),
        ];
      }
      activeUserId = nextUserId;
      syncing = true;
      if (activeUserId == null) {
        container.read(favoritesProvider.notifier).state = {};
        container.read(recentHomestaysProvider.notifier).state = [];
      } else {
        if (!favoritesByUser.containsKey(activeUserId)) {
          favoritesByUser[activeUserId!] = {...legacyFavorites};
          recentHomestaysByUser[activeUserId!] = [...legacyRecentHomestays];
          legacyFavorites = {};
          legacyRecentHomestays = [];
        }
        container.read(favoritesProvider.notifier).state = {
          ...favoritesByUser[activeUserId!]!,
        };
        container.read(recentHomestaysProvider.notifier).state = [
          ...recentHomestaysByUser[activeUserId!]!,
        ];
      }
      syncing = false;
      previous = null;
      save();
    });
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
          final externalFavoritesByUser = Map<String, dynamic>.from(
            data['favoritesByUser'] as Map? ?? const {},
          );
          for (final entry in externalFavoritesByUser.entries) {
            favoritesByUser[entry.key] = Set<String>.from(entry.value as List);
          }
          final externalRecentByUser = Map<String, dynamic>.from(
            data['recentHomestaysByUser'] as Map? ?? const {},
          );
          for (final entry in externalRecentByUser.entries) {
            recentHomestaysByUser[entry.key] = List<String>.from(
              entry.value as List,
            );
          }
          container
              .read(favoritesProvider.notifier)
              .state = activeUserId == null
              ? <String>{}
              : {...(favoritesByUser[activeUserId!] ?? const <String>{})};
          container
              .read(recentHomestaysProvider.notifier)
              .state = activeUserId == null
              ? <String>[]
              : [...(recentHomestaysByUser[activeUserId!] ?? const <String>[])];
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

  void _setStorageNotice(ProviderContainer container, String? notice) {
    try {
      container.read(storageNoticeProvider.notifier).state = notice;
    } catch (_) {
      // A sign-in event may finish after its tab/container is closed.
    }
  }

  static final List<FinanceEntry> _demoFinanceEntries = [
    _demoExpense('05-01', 'Vệ sinh và giặt là', 'Vận hành', 680000, 5, 8),
    _demoExpense('05-02', 'Điện nước tháng 5', 'Điện nước', 1240000, 5, 24),
    _demoExpense('06-01', 'Bảo trì điều hòa', 'Bảo trì', 950000, 6, 11),
    _demoExpense('06-02', 'Vật dụng phòng nghỉ', 'Vật tư', 430000, 6, 26),
    _demoExpense('07-01', 'Vệ sinh và giặt là', 'Vận hành', 760000, 7, 9),
    _demoExpense('07-02', 'Điện nước tháng 7', 'Điện nước', 1380000, 7, 24),
    _demoExpense('08-01', 'Thay khóa cửa phòng', 'Bảo trì', 620000, 8, 6),
    _demoExpense('08-02', 'Vật dụng phòng nghỉ', 'Vật tư', 510000, 8, 25),
    _demoExpense('09-01', 'Vệ sinh và giặt là', 'Vận hành', 720000, 9, 10),
    _demoExpense('09-02', 'Điện nước tháng 9', 'Điện nước', 1190000, 9, 24),
    _demoExpense('10-01', 'Bảo trì bình nóng lạnh', 'Bảo trì', 840000, 10, 7),
    _demoExpense('10-02', 'Vật dụng phòng nghỉ', 'Vật tư', 390000, 10, 18),
  ];

  static FinanceEntry _demoExpense(
    String suffix,
    String title,
    String category,
    int amount,
    int month,
    int day,
  ) => FinanceEntry(
    id: 'HHL-COST-DEMO-2026-$suffix',
    title: title,
    category: category,
    amount: amount,
    date: DateTime.utc(2026, month, day),
    note: 'Dữ liệu demo phục vụ kiểm thử và trình bày đồ án.',
    status: FinanceEntryStatus.paid,
  );
}

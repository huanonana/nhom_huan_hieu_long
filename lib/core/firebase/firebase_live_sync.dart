import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/booking/data/demo_booking_repository.dart';
import '../../features/dashboard/domain/finance_entry.dart';
import '../../features/dashboard/domain/staff_member.dart';
import '../../features/dashboard/domain/staff_shift.dart';
import '../state/app_state.dart';
import 'firebase_providers.dart';
import 'firebase_document_store.dart';

/// Keeps public catalog data and the active account's data live in sync.
/// Local storage stays available if a listener temporarily loses its network.
class FirebaseLiveSync {
  FirebaseLiveSync(this._container, this._store);

  final ProviderContainer _container;
  final FirebaseDocumentStore _store;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Map<String, String> _errors = {};
  ProviderSubscription<AsyncValue<AppUser?>>? _authListener;
  String? _activeUid;
  AppUserRole? _activeRole;
  bool _closed = false;

  void start() {
    _listen('homestays', _store.watchPublicHomestays(), (homes) {
      _repository.mergeCloudCatalog(homes: homes);
      _refresh();
    });
    _listen('rooms', _store.watchPublicRooms(), (rooms) {
      _repository.mergeCloudCatalog(rooms: rooms);
      _refresh();
    });
    _listen('reviews', _store.watchPublicReviews(), (reviews) {
      _repository.mergeCloudCatalog(reviews: reviews);
      _refresh();
    });

    // Riverpod turns Firebase Auth changes into profile snapshots. Listening
    // here handles both a saved session at startup and sign-in after startup.
    _authListener = _container.listen(currentUserProvider, (_, next) {
      if (next is AsyncError<AppUser?>) {
        _setError('auth', 'Chưa đọc được tài khoản Firebase. Kiểm tra mạng.');
      } else if (next is AsyncData<AppUser?>) {
        _clearErrors(const ['auth']);
        _watchAccount(next.value);
      }
    }, fireImmediately: true);
  }

  DemoBookingRepository get _repository {
    final repository = _container.read(repositoryProvider);
    if (repository is! DemoBookingRepository) {
      throw StateError('Firebase sync cần DemoBookingRepository.');
    }
    return repository;
  }

  void _watchAccount(AppUser? user) {
    if (_activeUid == user?.uid && _activeRole == user?.role) return;
    _activeUid = user?.uid;
    _activeRole = user?.role;
    _cancelAccountListeners();
    _clearErrors(const ['bookings', 'finance', 'staff', 'shifts']);
    if (user == null) return;

    final bookingStream = user.role == AppUserRole.host
        ? _store.watchAllBookingsForDemo()
        : _store.watchBookingsForGuest(user.uid);
    _listen('bookings', bookingStream, (bookings) {
      _repository.mergeCloudBookings(bookings);
      _refresh();
    }, accountScoped: true);

    if (user.role == AppUserRole.host) {
      _listen('finance', _store.watchAllFinanceEntries(), (entries) {
        _mergeById<FinanceEntry>(
          financeEntriesProvider,
          entries,
          (entry) => entry.id,
        );
      }, accountScoped: true);
      _listen('staff', _store.watchAllStaffMembers(), (members) {
        _mergeById<StaffMember>(
          staffMembersProvider,
          members,
          (member) => member.id,
        );
      }, accountScoped: true);
      _listen('shifts', _store.watchAllStaffShifts(), (shifts) {
        _mergeById<StaffShift>(
          staffShiftsProvider,
          shifts,
          (shift) => shift.id,
        );
      }, accountScoped: true);
    }
  }

  void _mergeById<T>(
    StateProvider<List<T>> provider,
    List<T> cloud,
    String Function(T) idOf,
  ) {
    final merged = {
      for (final item in _container.read(provider)) idOf(item): item,
    };
    for (final item in cloud) {
      merged[idOf(item)] = item;
    }
    _container.read(provider.notifier).state = merged.values.toList();
    _refresh();
  }

  void _listen<T>(
    String key,
    Stream<List<T>> stream,
    void Function(List<T>) apply, {
    bool accountScoped = false,
  }) {
    final subscription = stream.listen(
      (items) {
        if (_closed) return;
        try {
          apply(items);
          _clearErrors([key]);
        } catch (error) {
          debugPrint(
            'Firebase sync apply failed for $key (${error.runtimeType}).',
          );
          _setError(
            key,
            'Có dữ liệu Firebase chưa tải được. App vẫn giữ dữ liệu đã lưu.',
          );
        }
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Firebase listener failed for $key (${error.runtimeType}).');
        _setError(
          key,
          'Chưa đồng bộ được dữ liệu $key. Kiểm tra mạng và quyền Firebase.',
        );
      },
    );
    if (accountScoped) {
      _accountSubscriptions.add(subscription);
    } else {
      _subscriptions.add(subscription);
    }
  }

  final List<StreamSubscription<dynamic>> _accountSubscriptions = [];

  void _cancelAccountListeners() {
    for (final subscription in _accountSubscriptions) {
      unawaited(subscription.cancel());
    }
    _accountSubscriptions.clear();
  }

  void _setError(String key, String message) {
    _errors[key] = message;
    _publishError();
  }

  void _clearErrors(Iterable<String> keys) {
    for (final key in keys) {
      _errors.remove(key);
    }
    _publishError();
  }

  void _publishError() {
    _container.read(firebaseSyncNoticeProvider.notifier).state =
        _errors.values.firstOrNull;
  }

  void _refresh() =>
      _container.read(changesProvider.notifier).refreshFromStorage();

  Future<void> close() async {
    _closed = true;
    _authListener?.close();
    _cancelAccountListeners();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/booking/data/demo_booking_repository.dart';
import 'package:nhom_huan_hieu/features/booking/domain/booking.dart';
import 'package:nhom_huan_hieu/main.dart';
import 'package:nhom_huan_hieu/core/widgets/stay_widgets.dart';
import 'package:nhom_huan_hieu/features/auth/domain/app_user.dart';
import 'package:nhom_huan_hieu/features/auth/presentation/auth_provider.dart';

void main() {
  testWidgets('Overnight shortcut selects one night and keeps guest count', (
    tester,
  ) async {
    final container = ProviderContainer();
    container.read(roleProvider.notifier).state = DemoRole.guest;
    container.read(staySearchProvider.notifier).state = const StaySearch(
      guests: 2,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/explore');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bạn muốn đi đâu?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qua đêm'));
    await tester.pumpAndSettle();
    final selection = container.read(staySearchProvider);
    expect(selection.dates!.duration.inDays, 1);
    expect(selection.guests, 2);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
  testWidgets(
    'Search dates and guests carry into booking and confirmation submits once',
    (tester) async {
      final repo = DemoBookingRepository(seed: false);
      final start = vietnamToday(repo.now).add(const Duration(days: 2));
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWith(
            (ref) => Stream.value(
              AppUser(
                uid: 'guest-test-1',
                email: 'guest@example.invalid',
                displayName: 'Khách kiểm thử',
                role: AppUserRole.guest,
                createdAt: DateTime(2026),
              ),
            ),
          ),
        ],
      );
      container.read(roleProvider.notifier).state = DemoRole.guest;
      container.read(staySearchProvider.notifier).state = StaySearch(
        dates: DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 2)),
        ),
        guests: 3,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      container.read(routerProvider).go('/book/pine-2');
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Xác nhận yêu cầu đặt phòng'), 250);
      await tester.tap(find.text('Xác nhận yêu cầu đặt phòng'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 khách • 2 đêm'), findsOneWidget);
      expect(repo.bookings, isEmpty);
      await tester.tap(find.text('Gửi yêu cầu'));
      await tester.pumpAndSettle();
      expect(repo.bookings.single.guests, 3);
      expect(repo.bookings.single.total, 1805000);
      expect(repo.bookings.single.guestId, 'guest-test-1');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );
  testWidgets('Booking form pre-fills the signed-in guest name', (
    tester,
  ) async {
    final repo = DemoBookingRepository(seed: false);
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWith(
          (ref) => Stream.value(
            AppUser(
              uid: 'guest-prefill-test',
              email: 'guest-prefill@example.invalid',
              displayName: 'Nguyễn Khách Demo',
              role: AppUserRole.guest,
              createdAt: DateTime(2026),
            ),
          ),
        ),
      ],
    );
    container.read(roleProvider.notifier).state = DemoRole.guest;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/book/pine-2');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Nguyễn Khách Demo',
    );
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
  testWidgets('Price sort changes displayed home order and filters apply', (
    tester,
  ) async {
    final container = ProviderContainer();
    container.read(roleProvider.notifier).state = DemoRole.guest;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/explore');
    await tester.pumpAndSettle();
    await reveal(tester, find.byTooltip('Sắp xếp'), 200);
    await tester.tap(find.byTooltip('Sắp xếp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giá giảm dần'));
    await tester.pumpAndSettle();
    // All cards are built in the responsive Wrap; compare layout order.
    expect(
      tester.getTopLeft(find.text('Hiên Nhà Biển')).dy <=
          tester.getTopLeft(find.text('Nhà Bên Đồi')).dy,
      isTrue,
    );
    await tester.tap(find.text('Bộ lọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Hồ bơi'));
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.text('Vườn Nắng'), findsOneWidget);
    expect(find.text('Hiên Nhà Biển'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
  testWidgets('Host calendar exposes occupied date and rejects guest route', (
    tester,
  ) async {
    final repo = DemoBookingRepository();
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    container.read(roleProvider.notifier).state = DemoRole.guest;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    container.read(routerProvider).go('/host/calendar');
    await tester.pumpAndSettle();
    expect(find.text('Lịch phòng'), findsNothing);
    container.read(roleProvider.notifier).state = DemoRole.host;
    container.read(routerProvider).go('/host/calendar');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ngày sau'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ngày sau'));
    await tester.pumpAndSettle();
    await reveal(tester, find.textContaining('HHL-0001'), 180);
    expect(find.textContaining('HHL-0001'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
  testWidgets('Host edits room on mobile and updated room appears in catalog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = DemoBookingRepository(seed: false);
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    container.read(roleProvider.notifier).state = DemoRole.host;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    final roomRow = find.byKey(const ValueKey('pine-1'));
    await reveal(tester, find.textContaining('Phòng thông xanh'), 200);
    await tester.drag(
      find.textContaining('Phòng thông xanh'),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: roomRow, matching: find.text('Sửa')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Phòng mới sửa');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(repo.rooms.first.name, 'Phòng mới sửa');
    // Rendering errors are reported by the test binding.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
  testWidgets('Admin dashboard shows real demo revenue and operations stats', (
    tester,
  ) async {
    final repo = DemoBookingRepository(seed: false);
    repo.ensureRevenueDemoBookings();
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    container.read(roleProvider.notifier).state = DemoRole.host;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/host');
    await tester.pumpAndSettle();
    expect(find.text('Tổng quan quản trị'), findsOneWidget);
    await reveal(tester, find.text('Doanh thu theo tháng'), 300);
    expect(find.text('Doanh thu theo tháng'), findsOneWidget);
    expect(
      repo.bookings
          .where((booking) => booking.status == BookingStatus.checkedOut)
          .fold<int>(0, (sum, booking) => sum + booking.total),
      7460000,
    );
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('Admin adds a homestay and it is saved in the catalog', (
    tester,
  ) async {
    final repo = DemoBookingRepository(seed: false);
    final initialHomestayCount = repo.homestays.length;
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    container.read(roleProvider.notifier).state = DemoRole.host;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/host');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Thêm homestay, ảnh & phòng đầu tiên'), 200);
    await tester.tap(find.text('Thêm homestay, ảnh & phòng đầu tiên'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm homestay'), findsWidgets);
    expect(find.textContaining('khách sẽ nhìn thấy'), findsOneWidget);
    expect(find.text('Thêm phòng khác'), findsNothing);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nhà Vườn Demo');
    await tester.enterText(fields.at(1), 'Cần Thơ');
    await tester.enterText(fields.at(2), '12 Đường Hoa, Cần Thơ');
    await tester.enterText(
      fields.at(3),
      'Homestay thử nghiệm của quản trị viên.',
    );
    await tester.enterText(fields.at(4), 'Wi-Fi, Bếp');
    await tester.enterText(fields.at(5), 'Phòng sân vườn');
    await tester.enterText(fields.at(6), '780000');
    await tester.enterText(fields.at(7), '3');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(repo.homestays, hasLength(initialHomestayCount + 1));
    final added = repo.homestays.singleWhere(
      (home) => home.name == 'Nhà Vườn Demo',
    );
    expect(added.city, 'Cần Thơ');
    expect(added.amenities, containsAll(['Wi-Fi', 'Bếp']));
    expect(
      repo.rooms.where((room) => room.homestayId == added.id).single.name,
      'Phòng sân vườn',
    );
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
  testWidgets('Explore filters by search and opens homestay rooms', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container.read(roleProvider.notifier).state = DemoRole.guest;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/explore');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bạn muốn đi đâu?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'không có nơi này');
    await tester.ensureVisible(find.text('Xem chỗ ở phù hợp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem chỗ ở phù hợp'));
    await tester.pumpAndSettle();
    await reveal(tester, find.textContaining('Chưa có kết quả.'), 200);
    expect(find.textContaining('Chưa có kết quả.'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('không có nơi này'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Nhà Bên Đồi');
    await tester.ensureVisible(find.text('Xem chỗ ở phù hợp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem chỗ ở phù hợp'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Xem phòng'), 200);
    await tester.tap(find.text('Xem phòng').first);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Nhà Bên Đồi'), 150);
    expect(find.text('Nhà Bên Đồi'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('Host can approve a guest request and guest sees confirmation', (
    tester,
  ) async {
    final repo = DemoBookingRepository(seed: false);
    final start = DateTime.now().add(const Duration(days: 2));
    repo.create(
      roomId: 'pine-1',
      guestId: 'guest-demo',
      guestName: 'Hiếu',
      checkIn: start,
      checkOut: start.add(const Duration(days: 2)),
      guests: 2,
    );
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    container.read(roleProvider.notifier).state = DemoRole.host;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    container.read(routerProvider).go('/bookings');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Duyệt đơn'), 200);
    await tester.tap(find.text('Duyệt đơn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();
    expect(repo.bookings.single.status, BookingStatus.confirmed);
    expect(find.text('Đã xác nhận'), findsWidgets);
    container.read(roleProvider.notifier).state = DemoRole.guest;
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Chuyến đi của bạn'), -200);
    expect(find.text('Chuyến đi của bạn'), findsOneWidget);
    expect(find.text('Hủy yêu cầu'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('Mobile profile and demo role switch fit 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    expect(find.text('Tổng quan quản trị'), findsOneWidget);
    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Quản trị viên'), 120);
    await tester.tap(find.text('Quản trị viên'));
    await tester.pumpAndSettle();
    expect(find.text('Tổng quan quản trị'), findsOneWidget);
    // Rendering errors are reported by the test binding.
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> reveal(WidgetTester tester, Finder finder, double delta) async {
  await tester.scrollUntilVisible(
    finder.hitTestable(),
    delta,
    scrollable: find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

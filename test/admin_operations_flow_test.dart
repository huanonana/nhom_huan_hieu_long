import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/features/dashboard/domain/finance_entry.dart';
import 'package:nhom_huan_hieu/features/homestay/domain/catalog.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  testWidgets('finance dashboard explains revenue and charts seven months', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    container.read(roleProvider.notifier).state = DemoRole.host;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/host/finance');
    await tester.pumpAndSettle();

    expect(find.text('Xu hướng thu · chi'), findsOneWidget);
    expect(
      find.text('Dòng tiền ghi nhận trong 7 tháng gần nhất'),
      findsOneWidget,
    );
    expect(find.text('Tiền đã thu'), findsOneWidget);
    expect(find.text('Thu sau chi'), findsOneWidget);
    expect(find.textContaining('đơn có giao dịch'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('admin can record an operating expense', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    container.read(roleProvider.notifier).state = DemoRole.host;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/host/finance');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm khoản chi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Vệ sinh kiểm thử');
    await tester.enterText(find.byType(TextField).at(1), '125000');
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.pumpAndSettle();

    final entry = container.read(financeEntriesProvider).single;
    expect(entry.title, 'Vệ sinh kiểm thử');
    expect(entry.amount, 125000);
    expect(entry.status, FinanceEntryStatus.paid);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('admin can update a room housekeeping status', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    container.read(roleProvider.notifier).state = DemoRole.host;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/host/housekeeping');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cập nhật vệ sinh').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đang dọn').last);
    await tester.pumpAndSettle();

    expect(
      container
          .read(repositoryProvider)
          .rooms
          .any(
            (room) => room.housekeepingStatus == HousekeepingStatus.cleaning,
          ),
      isTrue,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}

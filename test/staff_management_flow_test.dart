import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  testWidgets('staff profile can be reused in a linked shift', (tester) async {
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
    container.read(routerProvider).go('/host/staff');
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ nhân viên'), findsOneWidget);

    await tester.tap(find.text('Thêm nhân viên'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Lê An');
    await tester.enterText(fields.at(1), 'Lễ tân');
    await tester.enterText(fields.at(2), '0901234567');
    await tester.enterText(fields.at(3), 'an@example.test');
    await tester.tap(find.text('Lưu nhân viên'));
    await tester.pumpAndSettle();

    final member = container.read(staffMembersProvider).single;
    expect(member.name, 'Lê An');
    expect(member.phone, '0901234567');
    expect(member.email, 'an@example.test');

    await tester.tap(find.text('Xếp ca'));
    await tester.pumpAndSettle();
    expect(find.text('Lê An · Lễ tân'), findsOneWidget);
    await tester.tap(find.text('Lưu ca'));
    await tester.pumpAndSettle();

    final shift = container.read(staffShiftsProvider).single;
    expect(shift.staffId, member.id);
    expect(shift.staffName, member.name);
    expect(find.text('Đã xếp ca'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}

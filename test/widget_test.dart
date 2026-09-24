import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  testWidgets('Home introduces homestay and opens team information', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Homestay HHL'), findsOneWidget);
    expect(find.text('Quản lý phòng'), findsOneWidget);
    expect(find.text('Chưa triển khai'), findsWidgets);
    expect(find.textContaining('Phạm Văn Huấn — 23010331'), findsNothing);

    await tester.tap(find.byTooltip('Thông tin nhóm'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Phạm Văn Huấn — 23010331'), findsOneWidget);
    expect(
      find.textContaining('Nguyễn Hữu Lê Hiếu — 23010985'),
      findsOneWidget,
    );
    expect(find.textContaining('Nguyễn Hải Long — 2301872'), findsOneWidget);

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Home fits a narrow mobile screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.scrollUntilVisible(
      find.text('Thông tin nhóm phát triển'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thông tin nhóm phát triển'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

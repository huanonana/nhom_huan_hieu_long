import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/core/widgets/location_photo_data.dart';
import 'package:nhom_huan_hieu/core/widgets/stay_gallery.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  test('Each destination has three non-reused photo assets', () {
    expect(locationPhotos, hasLength(14));
    for (final photos in locationPhotos.values) {
      expect(photos, hasLength(3));
    }
    final assetPaths = locationPhotos.values
        .expand((photos) => photos.map((photo) => photo.asset))
        .toSet();
    expect(assetPaths, hasLength(42));
    final sourcePages = locationPhotos.values
        .expand((photos) => photos.map((photo) => photo.source))
        .toSet();
    expect(sourcePages, hasLength(42));
  });
  test('All offline photo assets are bundled', () async {
    for (final photo in locationPhotos.values.expand((photos) => photos)) {
      final asset = await rootBundle.load(photo.asset);
      expect(asset.lengthInBytes, greaterThan(0), reason: photo.asset);
    }
  });
  test('Every photo has a verification status and source note', () {
    var verifiedCount = 0;
    var referenceCount = 0;
    for (final photos in locationPhotos.values) {
      for (final photo in photos) {
        expect(photo.sourceNote, isNotEmpty);
        if (photo.verified) {
          verifiedCount++;
        } else {
          referenceCount++;
          expect(
            photo.sourceNote,
            'Ảnh tham khảo, chưa xác nhận đúng địa điểm',
          );
        }
      }
    }
    expect(verifiedCount, 1);
    expect(referenceCount, 41);
  });
  testWidgets(
    'Gallery changes image and opens the selected photo with credit',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StayGallery('pine'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Ảnh tiếp theo'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Ảnh trước'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.tap(find.byType(PageView));
      await tester.pumpAndSettle();
      expect(find.text('Album ảnh tham khảo'), findsOneWidget);
      expect(find.textContaining('Ảnh:'), findsOneWidget);
      await tester.tap(find.byTooltip('Ảnh tiếp theo').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Ảnh:'), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng ảnh'));
      await tester.pumpAndSettle();
      expect(find.text('Album ảnh tham khảo'), findsNothing);
    },
  );

  testWidgets(
    'Quick pool category filters homes and brings results into view',
    (tester) async {
      final container = ProviderContainer();
      container.read(roleProvider.notifier).state = DemoRole.guest;
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Có hồ bơi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Có hồ bơi'));
      await tester.pumpAndSettle();
      expect(find.text('4 homestay phù hợp'), findsOneWidget);
      expect(find.text('Vườn Nắng'), findsOneWidget);
      expect(find.text('Hiên Nhà Biển'), findsNothing);
      expect(
        find.text('Không gian dành cho bạn').hitTestable(),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );
}

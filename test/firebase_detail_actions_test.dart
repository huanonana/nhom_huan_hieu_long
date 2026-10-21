import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/core/state/app_state.dart';
import 'package:nhom_huan_hieu/core/router/app_router.dart';
import 'package:nhom_huan_hieu/features/auth/presentation/auth_provider.dart';
import 'package:nhom_huan_hieu/features/booking/presentation/firebase_pages.dart';
import 'package:nhom_huan_hieu/features/booking/presentation/firestore_repository_provider.dart';
import 'package:nhom_huan_hieu/features/homestay/domain/catalog.dart';
import 'package:nhom_huan_hieu/features/review/domain/review.dart';
import 'package:nhom_huan_hieu/main.dart';

void main() {
  testWidgets('Firebase homestay details connect favorites and room booking', (
    tester,
  ) async {
    final home = Homestay(
      id: 'garden',
      hostId: 'host-1',
      name: 'Vườn Nắng',
      city: 'Hội An',
      address: 'Cẩm Thanh',
      description: 'Nhà nghỉ thoáng sáng.',
      amenities: const ['Wi-Fi', 'Bếp'],
      color: 0xFF2F6757,
    );
    final room = Room(
      id: 'garden-room',
      homestayId: home.id,
      name: 'Phòng vườn',
      price: 590000,
      capacity: 3,
    );

    final container = ProviderContainer(
      overrides: [
        useFirebaseBackendProvider.overrideWithValue(true),
        firestoreHomestaysProvider.overrideWith((ref) => Stream.value([home])),
        firestoreRoomsProvider.overrideWith((ref) => Stream.value([room])),
        firestoreReviewsProvider.overrideWith(
          (ref) => Stream.value(const <StayReview>[]),
        ),
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    container.read(roleProvider.notifier).state = DemoRole.guest;
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/homestays/garden');
    await tester.pumpAndSettle();

    expect(find.text('Đặt phòng'), findsOneWidget);
    final favoriteButton = find.byKey(
      const ValueKey('firebase-detail-favorite'),
    );
    expect(favoriteButton, findsOneWidget);
    tester.widget<OutlinedButton>(favoriteButton).onPressed!.call();
    await tester.pumpAndSettle();
    expect(container.read(favoritesProvider), contains(home.id));
    expect(find.text('Đã yêu thích'), findsOneWidget);
    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(FirebaseDetailPage)),
      ).read(favoritesProvider),
      contains(home.id),
    );
    final bookButton = find.byKey(const ValueKey('firebase-detail-book'));
    expect(bookButton, findsOneWidget);
    tester.widget<FilledButton>(bookButton).onPressed!.call();
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/book/garden-room',
    );
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}

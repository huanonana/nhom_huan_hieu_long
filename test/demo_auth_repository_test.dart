import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/features/auth/data/demo_auth_repository.dart';
import 'package:nhom_huan_hieu/features/auth/domain/app_user.dart';

void main() {
  final auth = DemoAuthRepository.instance;

  setUp(() {
    auth.setPersistence(null);
    auth.restoreSnapshot(
      jsonEncode({'version': 1, 'currentUid': null, 'accounts': []}),
    );
  });

  tearDown(() {
    auth.setPersistence(null);
    auth.restoreSnapshot(
      jsonEncode({'version': 1, 'currentUid': null, 'accounts': []}),
    );
  });

  test(
    'local guest and host accounts register, sign in, and reject bad passwords',
    () async {
      final guest = await auth.signUp(
        email: ' Guest@Example.invalid ',
        password: 'guest-pass-123',
        role: AppUserRole.guest,
        displayName: 'Khách demo',
      );
      await auth.signOut();
      final host = await auth.signUp(
        email: 'host@example.invalid',
        password: 'host-pass-123',
        role: AppUserRole.host,
        displayName: 'Chủ nhà demo',
      );

      expect(guest.email, 'guest@example.invalid');
      expect(guest.role, AppUserRole.guest);
      expect(host.role, AppUserRole.host);
      expect(
        () => auth.signIn(email: guest.email, password: 'incorrect-password'),
        throwsA(isA<DemoAuthException>()),
      );

      await auth.signIn(
        email: ' GUEST@example.invalid ',
        password: 'guest-pass-123',
      );
      expect(auth.signedInUser?.uid, guest.uid);
      await auth.signIn(email: host.email, password: 'host-pass-123');
      expect(auth.signedInUser?.role, AppUserRole.host);
    },
  );

  test(
    'duplicate local email is rejected and stored snapshots omit plaintext password',
    () async {
      await auth.signUp(
        email: 'same@example.invalid',
        password: 'secret-pass-789',
        role: AppUserRole.guest,
      );

      await expectLater(
        auth.signUp(
          email: 'SAME@example.invalid',
          password: 'another-pass-456',
          role: AppUserRole.host,
        ),
        throwsA(isA<DemoAuthException>()),
      );
      await auth.signOut();
      final snapshot = auth.exportSnapshot();
      expect(snapshot, contains('passwordHash'));
      expect(snapshot, contains('salt'));
      expect(snapshot, isNot(contains('secret-pass-789')));
      auth.restoreSnapshot(snapshot);
      expect(auth.signedInUser, isNull);
      final restored = await auth.signIn(
        email: 'same@example.invalid',
        password: 'secret-pass-789',
      );
      expect(restored.email, 'same@example.invalid');
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom_huan_hieu/features/auth/presentation/social_auth_buttons.dart';

void main() {
  testWidgets(
    'social providers show a coming soon message without signing in',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocialAuthButtons())),
      );

      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      await tester.tap(find.text('Google'));
      await tester.pump();

      expect(find.text('Đăng nhập Google sẽ sớm được hỗ trợ.'), findsOneWidget);
    },
  );
}

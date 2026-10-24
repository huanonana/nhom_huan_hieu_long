import '../data/demo_auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is DemoAuthException) return error.message;
  if (error is FirebaseAuthException &&
      error.code == 'host-provisioning-required') {
    return error.message ?? 'Tài khoản quản lý phải được cấp riêng.';
  }
  return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
}

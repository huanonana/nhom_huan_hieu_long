import '../data/demo_auth_repository.dart';

String authErrorMessage(Object error) {
  if (error is DemoAuthException) return error.message;
  return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
}

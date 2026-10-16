import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException)
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  return switch (error.code) {
    'invalid-email' => 'Địa chỉ email chưa đúng định dạng.',
    'user-not-found' ||
    'invalid-credential' => 'Email hoặc mật khẩu không đúng.',
    'wrong-password' => 'Mật khẩu không chính xác.',
    'email-already-in-use' => 'Email này đã được đăng ký.',
    'weak-password' => 'Mật khẩu cần có ít nhất 6 ký tự.',
    'too-many-requests' =>
      'Bạn thử quá nhiều lần. Hãy đợi một chút rồi thử lại.',
    'network-request-failed' => 'Không có kết nối mạng. Hãy kiểm tra Internet.',
    'operation-not-allowed' => 'Đăng nhập Email/Password chưa được bật.',
    _ => 'Không thể xác thực lúc này. Vui lòng thử lại.',
  };
}

# Kết quả kiểm tra bản thử ban đầu

Ngày kiểm tra: 25/09/2026. Flutter 3.35.2 / Dart 3.9.0.

## Đã đạt

- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: 12 test đạt (9 nghiệp vụ, 3 giao diện).
- `flutter build web --no-pub`: tạo thành công `build/web`.
- `flutter build apk --debug --no-pub`: tạo thành công
  `build/app/outputs/flutter-apk/app-debug.apk` (143.554.172 byte).
- Trình duyệt: mở khám phá → Nhà Bên Đồi → Phòng gác mái → chọn
  25/09/2026–27/09/2026 → tổng tiền 1.900.000 VND → gửi yêu cầu.
- Chuyển sang vai trò Host thử nghiệm: tổng quan hiển thị 1 đơn chờ;
  duyệt HHL-0002 → trạng thái đổi thành đã xác nhận.
- Kiểm tra đường dẫn local Android đã trỏ SDK và Flutter sang ổ D.

## Giới hạn

Kiểm thử trên bộ nhớ trong một phiên, không phải Firebase hoặc nhiều thiết bị.
Chưa kiểm tra cổng thanh toán, QR, thông báo, Admin hay lưu trữ thật vì chưa
triển khai. Không điều khiển emulator dùng chung với project khác.
APK đã build nhưng chưa cài/chạy trên thiết bị. Không coi build thành công là
bằng chứng đã kiểm tra tương tác thực tế trên Android.

## Cập nhật 26/09/2026 — quản lý danh mục và lưu demo

- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: 19/19 đạt (15 nghiệp vụ/lưu trữ, 4 giao diện).
- Thêm kiểm thử quyền quản lý, giá/sức chứa, chặn bảo trì/xóa khi còn đơn,
  giữ snapshot đơn cũ, tuần tự ID sau khôi phục, đọc dữ liệu lỗi không ghi đè,
  báo lỗi ghi và thử lưu lại ở thao tác sau.
- Widget test sửa phòng tại 320px không lỗi tràn giao diện.
- Web build thành công; thử trực tiếp sửa tên phòng gác mái, tải lại trình duyệt,
  chọn lại vai trò Host: tên mới vẫn giữ trong danh mục.
- Lưu cục bộ chỉ phục vụ demo một thiết bị/một tab; chưa kiểm chứng Firebase,
  đa thiết bị hoặc giao dịch phân tán. Không coi shared_preferences là database
  cho đơn đặt thật: https://pub.dev/packages/shared_preferences.
- APK debug bản cập nhật build thành công (142 giây), chưa cài/chạy trên thiết bị.

## Giao diện 27/09/2026

- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: 22/22 đạt.
- Thêm kiểm thử truyền ngày/số khách, xem lại đơn trước khi gửi,
  sắp xếp giá và áp dụng bộ lọc tiện nghi, lịch phòng và chặn route Host đối với Guest.
- Kiểm tra tìm phòng → chi tiết, tài khoản, sửa phòng tại 320px; sửa lỗi co giãn
  thanh tiêu đề trên màn nhỏ. Các ca nghiệp vụ/lưu cục bộ vẫn đạt.

- Bổ sung lựa chọn qua đêm, kiểm tra giữ số khách; tổng kiểm thử cuối: 23/23 đạt. Phân tích code không lỗi.
- Bản cuối: Web và APK debug build thành công; đã xác minh 3 ảnh minh họa nằm trong APK. Chưa cài APK trên thiết bị.

## Kiểm tra 28/09/2026
- 25/25 kiểm thử đạt, gồm thêm chuyển ảnh / nguồn ảnh / đóng album toàn màn hình ở chiều rộng 320px và lối tắt hồ bơi lọc đúng rồi cuộn tới kết quả.
- 42 ảnh JPEG chỗ nghỉ tham khảo riêng theo 14 homestay mẫu đã được bổ sung vào tài nguyên app (3 ảnh mỗi căn).
- Phân tích mã không có lỗi; build web và APK debug thành công. Kiểm tra ZIP của APK có đủ 9 JPEG, không còn đóng gói PNG AI cũ.

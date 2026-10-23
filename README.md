# HHL Stay

Ứng dụng Flutter quản lý homestay, gồm trải nghiệm khách đặt phòng và khu vực quản trị chủ nhà. Mã nguồn ứng dụng chính nằm ngay ở thư mục gốc repo.

## Chạy ứng dụng

Cần Flutter stable có Dart 3.9 trở lên.

```bash
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Mở `http://127.0.0.1:8080`. Để chạy trên thiết bị Android/iOS, chọn thiết bị tương ứng trong `flutter run`.

## Tài khoản demo

App tự tạo hai tài khoản demo trên thiết bị khi khởi động lần đầu:

| Vai trò | Email | Mật khẩu |
| --- | --- | --- |
| Khách | `hhl-khach-demo-2026@example.com` | `HHLstayKhach2026!` |
| Quản trị viên | `hhl-admin-demo-2026@example.com` | `HHLstayAdmin2026!` |

Đây là tài khoản phục vụ trình diễn. Đăng ký, phiên đăng nhập, homestay, phòng, đơn đặt, đánh giá và yêu thích lưu cục bộ trên trình duyệt/thiết bị bằng SharedPreferences; chúng không đồng bộ sang máy khác và có thể mất khi xóa dữ liệu trình duyệt.

## Chức năng chính

- Khách khám phá, tìm kiếm và lọc homestay/phòng, xem chi tiết, chọn ngày/số khách, đặt phòng, theo dõi hoặc hủy đơn, lưu yêu thích và đánh giá sau khi trả phòng.
- Chủ nhà/quản trị viên quản lý homestay và phòng, xem lịch phòng, duyệt/từ chối đơn, nhận/trả phòng, bật bảo trì và theo dõi dashboard cùng báo cáo tài chính demo.
- Tư vấn và hỗ trợ nội dung bằng Gemini khi cấu hình API key; chatbot có chế độ tư vấn ngoại tuyến.
- Giao diện tiếng Việt, responsive, sử dụng Be Vietnam Pro.

## AI Gemini (tùy chọn)

Tạo key tại [Google AI Studio](https://aistudio.google.com/app/apikey), sau đó truyền key khi chạy:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --dart-define=GEMINI_API_KEY=YOUR_KEY
```

Không commit API key. Flutter Web đưa giá trị này vào mã JavaScript phía trình duyệt, vì vậy chỉ dùng key giới hạn cho demo; sản phẩm thật cần proxy qua backend. Không có key, các luồng đặt phòng và quản lý vẫn hoạt động, chatbot chuyển sang nội dung tư vấn có sẵn.

## Kiểm tra và build

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
```

## Tài liệu

- [Hướng dẫn chạy thử và luồng demo](docs/chay-ban-thu.md)
- [Đặc tả nghiệp vụ và phạm vi hiện tại](docs/dac-ta-app.md)
- [Thiết kế giao diện](docs/thiet-ke-giao-dien.md)
- [Nguồn ảnh homestay](docs/nguon-anh.md) và [nguồn ảnh địa danh](docs/nguon-anh-dia-danh.md)

## Giới hạn bản demo

Đây là ứng dụng demo học thuật, chưa dùng dịch vụ xác thực, cơ sở dữ liệu hoặc thanh toán tập trung. Số liệu doanh thu/chi tiêu được tính từ dữ liệu demo cục bộ, không đại diện giao dịch thật. Cần backend và phân quyền phía máy chủ trước khi triển khai công khai.

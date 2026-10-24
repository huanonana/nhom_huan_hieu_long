# HHL Stay

Ứng dụng Flutter quản lý homestay, gồm trải nghiệm khách đặt phòng và khu vực quản trị chủ nhà. Mã nguồn ứng dụng chính nằm ngay ở thư mục gốc repo.

## Chạy ứng dụng

Cần Flutter stable có Dart 3.9 trở lên.

```bash
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8083
```

Mở `http://127.0.0.1:8083`. Để chạy trên thiết bị Android/iOS, chọn thiết bị tương ứng trong `flutter run`.

## Chế độ dữ liệu

Mặc định app chạy chế độ local để demo ngoại tuyến ổn định. Để chạy với Firebase đã cấu hình cho dự án lớp:

```bash
flutter run -d chrome --dart-define=HHL_USE_FIREBASE=true
```

Ở chế độ Firebase, đăng ký/đăng nhập dùng Firebase Authentication, hồ sơ tài khoản được ghi vào `users`, và dữ liệu đơn đặt, homestay, phòng, đánh giá, tài chính, nhân viên, ca làm được tải/gộp khi khởi động rồi đồng bộ khi có thay đổi. Chế độ local vẫn dùng SharedPreferences và hai tài khoản bên dưới. Không chuyển dữ liệu local sang Firebase tự động.

Rules hiện nằm trong [firestore.rules](firestore.rules) và đã được triển khai lên Firebase project `hhl-stay-home-2026-23010895` để chạy đồ án. Đây là rules phát triển rất rộng (đọc công khai, người đăng nhập được ghi); **không dùng cho ứng dụng thật**. Firebase client config chỉ trỏ tới project, không chứa service-account credential.

## Tài khoản demo local

App tự tạo hai tài khoản demo trên thiết bị khi khởi động lần đầu:

| Vai trò | Email | Mật khẩu |
| --- | --- | --- |
| Khách | `hhl-khach-demo-2026@example.com` | `HHLstayKhach2026!` |
| Quản trị viên | `hhl-admin-demo-2026@example.com` | `HHLstayAdmin2026!` |

Đây là tài khoản phục vụ trình diễn ở chế độ local; chúng không phải tài khoản Firebase. Đăng ký, phiên đăng nhập, homestay, phòng, đơn đặt, đánh giá và yêu thích local lưu trên thiết bị bằng SharedPreferences.

## Chức năng chính

- Khách khám phá, tìm kiếm và lọc homestay/phòng, xem chi tiết, chọn ngày/số khách, đặt phòng, theo dõi hoặc hủy đơn, lưu yêu thích và đánh giá sau khi trả phòng.
- Chủ nhà/quản trị viên quản lý homestay và phòng, xem lịch phòng, duyệt/từ chối đơn, nhận/trả phòng, bật bảo trì và theo dõi dashboard cùng báo cáo tài chính demo.
- Tư vấn và hỗ trợ nội dung bằng Gemini khi cấu hình API key; chatbot có chế độ tư vấn ngoại tuyến.
- Giao diện tiếng Việt, responsive, sử dụng Be Vietnam Pro.

## AI Gemini (tùy chọn)

Tạo key tại [Google AI Studio](https://aistudio.google.com/app/apikey), sau đó truyền key khi chạy:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8083 --dart-define=GEMINI_API_KEY=YOUR_KEY
```

Không commit API key. Flutter Web đưa giá trị này vào mã JavaScript phía trình duyệt, vì vậy chỉ dùng key giới hạn cho demo; sản phẩm thật cần proxy qua backend. Không có key, các luồng đặt phòng và quản lý vẫn hoạt động, chatbot chuyển sang nội dung tư vấn có sẵn.

## Kiểm tra và build

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
# Firebase-enabled Android debug build
flutter build apk --debug --dart-define=HHL_USE_FIREBASE=true
```

## Tài liệu

- [Hướng dẫn chạy thử và luồng demo](docs/chay-ban-thu.md)
- [Đặc tả nghiệp vụ và phạm vi hiện tại](docs/dac-ta-app.md)
- [Thiết kế giao diện](docs/thiet-ke-giao-dien.md)
- [Nguồn ảnh homestay](docs/nguon-anh.md) và [nguồn ảnh địa danh](docs/nguon-anh-dia-danh.md)

## Giới hạn bản demo

Đây là ứng dụng demo học thuật. Local mode lưu dữ liệu trên thiết bị; Firebase mode có Auth và Firestore cho các luồng đã tích hợp. Rules hiện cho phép đọc công khai và mọi tài khoản đăng nhập ghi, vì vậy không lưu dữ liệu khách thật. Số liệu doanh thu/chi tiêu là dữ liệu demo, không đại diện giao dịch thật. Thanh toán, thông báo push, kiểm soát quyền theo chủ sở hữu, xử lý đặt trùng trên server và đồng bộ ngoại tuyến đầy đủ chưa có.

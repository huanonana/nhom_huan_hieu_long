# Ứng dụng quản lý Homestay HHL

## Đã triển khai

- Kiến trúc tách model, repository, state (Riverpod), màn hình và router (go_router).
- Khám phá 14 homestay và phòng demo ở 14 điểm đến Việt Nam. Tìm kiếm gọn mở
  bảng chọn điểm đến/ngày/số khách; banner và ảnh thẻ chỗ ở có thể vuốt.
- Tìm theo tên/khu vực; lọc thành phố, tiện nghi, sức chứa, giá tối đa và ngày ở.
- Xem homestay/phòng, chọn ngày, nhập tên khách và ghi chú, xem giá trước khi gửi.
- Kiểm tra ngày, số khách, 1–30 đêm, không trùng khoảng ở, giữ đơn chờ 24 giờ.
- Admin demo xem và xử lý tất cả đơn trong workspace dùng chung, kể cả dữ liệu lưu với owner ID cũ; Khách xem đơn của mình và hủy khi còn chờ. Admin duyệt/từ chối,
  xác minh nội dung QR của khách để nhận phòng và trả phòng; chặn nhận sai ngày, mã sai và chuyển sai trạng thái.
- Yêu thích lưu trên máy; trang Yêu thích có lưới riêng và trạng thái rỗng kèm nút quay lại khám phá.
- Dashboard quản trị có thẻ tổng giá trị đơn hoàn tất theo tháng, biểu đồ 6 tháng,
  tỷ lệ đêm phòng được giữ chỗ và số nhận/trả phòng hôm nay; số liệu tính từ
  đơn demo trên thiết bị, không phải tiền thực thu.
- Giao diện tiếng Việt, có trạng thái rỗng và thông báo lỗi.

- Admin demo tạo/sửa/xóa homestay và phòng, bật/tắt bảo trì. Xóa homestay yêu cầu xóa phòng trước.
- Chặn bảo trì/xóa phòng còn đơn chờ, xác nhận hoặc đang ở; sửa phòng giữ nguyên tên/giá trên đơn cũ.
- Lưu đơn, danh mục và yêu thích trên thiết bị bằng shared_preferences; có cảnh báo khi đọc/ghi thất bại.
- Ảnh chỗ nghỉ tham khảo từ Wikimedia Commons; mỗi homestay mẫu có 3 ảnh riêng, tổng 42 ảnh khác nhau cho 14 địa điểm. Tác giả, giấy phép và nguồn hiển thị khi mở toàn màn hình.
- Các hàng cuộn ngang hỗ trợ kéo bằng cảm ứng, chuột và trackpad.
- Khách đánh giá 1–5 sao kèm nhận xét sau khi trả phòng, một đánh giá cho mỗi đơn; danh sách và điểm trung bình lấy từ đánh giá đã lưu.

## Cách thử

Chạy tại thư mục gốc repo bằng Flutter 3.35.2:

```bash
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8083
```

Local mode là mặc định. Để đăng ký/đăng nhập Firebase và dùng Firestore của project lớp, chạy:

```bash
flutter run -d chrome --dart-define=HHL_USE_FIREBASE=true
flutter devices
flutter run -d <device-id> --dart-define=HHL_USE_FIREBASE=true
```

Android/Web Firebase được cấu hình cho project lớp. File [Rules](../firestore.rules)
cho phép đọc công khai danh mục và đánh giá, khách chỉ đọc/hủy đơn của chính
mình, còn số liệu tài chính/nhân viên và thao tác quản lý yêu cầu vai trò host.
Rules có sáu nhóm kiểm thử tự động trên Firestore Emulator; ca đánh giá sau trả
phòng kiểm tra luôn ID review trùng với document mapper. Để cấp tài khoản quản trị cho demo
Firebase: đăng ký tài khoản qua app với vai trò Khách, lấy UID trong Firebase
Authentication, rồi trong Firestore Console đặt `users/{UID}.role` thành
`host`. Vai trò không được cấp từ màn hình đăng ký. Hai tài khoản demo trong
bảng dưới chỉ dành cho chế độ local.

Tài khoản demo được tạo tự động khi ứng dụng khởi động lần đầu:

| Vai trò | Email | Mật khẩu |
| --- | --- | --- |
| Khách | `hhl-khach-demo-2026@example.com` | `HHLstayKhach2026!` |
| Quản trị viên (vai trò Host trong app) | `hhl-admin-demo-2026@example.com` | `HHLstayAdmin2026!` |

Đây là tài khoản học thuật lưu trên trình duyệt/thiết bị, không phải tài khoản máy chủ dùng chung. Dữ liệu của tài khoản nằm riêng theo origin và có thể được xóa trong cài đặt trình duyệt.

1. Mở app ở local mode. Đăng nhập bằng tài khoản quản trị trong bảng để vào **Tổng quan quản trị**; đăng xuất trước khi chuyển sang tài khoản khách. Không dựa vào nút đổi vai trò để thay cho đăng nhập.
2. Đăng nhập bằng tài khoản khách. Chọn **Nhà Bên Đồi → Xem phòng**, chọn ngày, số khách, nhập thông tin cần thiết và gửi yêu cầu.
3. Đăng xuất khách, đăng nhập quản trị rồi vào **Đơn đặt**. Tìm đơn vừa tạo, xem chi tiết và chọn **Duyệt đơn**.
4. Đăng xuất quản trị rồi đăng nhập lại bằng khách để xem trạng thái và QR. Sao chép nội dung mã; đăng nhập quản trị, vào **Đơn đặt → Xác minh mã & nhận phòng** và dán mã. Khi trả phòng xong, khách có thể đánh giá.
5. Thử đặt cùng phòng/cùng ngày: ứng dụng báo không còn trống.
6. Muốn thử nhận/trả phòng, đặt ngày nhận là hôm nay. Đơn đã xác nhận
   chỉ được nhận trong khoảng lưu trú, không nhận trước ngày và không nhận từ ngày trả.

Phòng thông xanh có sẵn một đơn mẫu từ ngày hiện tại +2 đến +4 để kiểm tra
lọc phòng trống. Bộ đếm thời hạn được cập nhật mỗi phút và kiểm tra lại khi thao tác.

7. Vào **Quản lý → Tổng quan quản trị**, thêm homestay rồi thêm phòng. Homestay chỉ xuất hiện ở Khám phá khi có phòng đang mở phù hợp bộ lọc.
8. Mở menu thao tác bên phòng để sửa giá, sức chứa hoặc bảo trì. Tải lại app; đăng nhập lại để xác nhận dữ liệu demo vẫn được giữ trên máy.

## Kịch bản demo dưới 8 phút

- **0:00–0:40 — Giới thiệu:** nêu đây là prototype Flutter cho khách đặt homestay và quản trị vận hành; dữ liệu địa điểm/giá là minh họa.
- **0:40–1:30 — Khám phá:** tìm một điểm đến, dùng bộ lọc, mở homestay, xem ảnh, tiện nghi, phòng và giá.
- **1:30–2:40 — Đặt phòng:** đăng nhập bằng tài khoản khách, chọn ngày/số khách, nhập mã `HHL10`, kiểm tra mức giảm thành viên và mã, xác nhận gửi đơn.
- **2:40–3:20 — Lịch sử khách:** mở **Đơn đặt**, cho thấy trạng thái chờ, giá và chi tiết đơn.
- **3:20–4:20 — Duyệt ở quản trị:** đăng xuất khách, đăng nhập quản trị, mở **Đơn đặt**, duyệt đơn vừa gửi và chỉ ra lịch phòng liên quan.
- **4:20–5:20 — Tài chính và vận hành:** xem dashboard/Finance, doanh thu theo kỳ, khoản thu chi và lịch bảo trì; nói rõ đây là số liệu demo, không phải tiền thực thu.
- **5:20–6:00 — Chốt:** nêu kiểm thử/build đã chạy, giới hạn local/Firebase, không có thanh toán thật và rules Firebase hiện chỉ dùng trong demo.

Kịch bản là lời dẫn; trước khi quay, đăng nhập thử cả hai tài khoản trên cùng trình duyệt/origin và kiểm tra dữ liệu đơn đã đồng bộ trong phiên local. Link video nộp bài phải là link mà giảng viên mở được, không dùng URL localhost.

## Phần chưa triển khai

Firebase Auth và Firestore có trong chế độ bật riêng; danh mục/booking/finance/staff
được đọc hoặc ghi theo các luồng tích hợp, nhưng chưa có đồng bộ đa thiết bị đầy đủ,
retry queue, xử lý xung đột hay phân quyền theo chủ sở hữu.
Chưa có thanh toán/tiền thực thu, FCM, ảnh xác thực của homestay và bản đồ thật.
Mã QR hiện là mã demo tạo từ ID đơn, chưa có token ngẫu nhiên, máy quét tích hợp hay xác minh qua máy chủ.
Không nhập dữ liệu nhạy cảm vào bản thử. Tải lại cùng trình duyệt/địa chỉ sẽ đọc dữ liệu đã lưu; xóa dữ liệu trình duyệt hoặc gỡ app có thể làm mất dữ liệu demo. Chỉ thử trên một tab tại một thời điểm, chưa hỗ trợ đồng bộ nhiều tab.
Local mode có thể tạo tài khoản Chủ nhà cho thử nghiệm trên thiết bị; đây không
thay thế phân quyền máy chủ. Firebase mode không cho tài khoản tự nâng quyền.

Xem [đặc tả bổ sung](dac-ta-app.md) về quy tắc nghiệp vụ và transaction Firebase.
Kiểm tra lại ngày 25/10/2026: `flutter analyze` sạch, 103/103 Flutter tests,
4/4 test tiện ích proxy local và 7/7 nhóm Firestore Rules Emulator đều qua.
Web release build và Android Firebase debug APK build thành công. Web localhost
đã mở được màn quản trị; kiểm tra console trình duyệt không ghi nhận lỗi. Một
câu hỏi gợi ý homestay Đà Lạt trên localhost:8083 nhận phản hồi live từ Gemini
và giao diện báo “Gemini đang hoạt động”; đây chỉ là smoke test một câu hỏi.
Bộ kiểm tra này không chạy Medium Phone và không cài APK lên thiết bị. Đây là
dữ liệu demo; Firebase E2E trên project thật, đồng bộ đa thiết bị, thanh toán
thật và iOS chưa được xác nhận.

APK kiểm thử nằm trong `output/builds/`: `hhl_stay_medium_phone_local_debug.apk`,
`hhl_stay_medium_phone_firebase_debug.apk` và `hhl_stay_medium_phone_local_release.apk`.
Local release chưa ký để phát hành store. Xem [kết quả kiểm thử](kiem-thu-ban-dau.md).

## Kiểm thử

```bash
flutter analyze
flutter test
flutter build web
```

Unit test kiểm tra ngày/giá/sức chứa, phòng bảo trì, trùng lịch, hai lệnh trong
cùng isolate, hết hạn, quyền chủ đơn/chủ nhà và vòng đời đơn. Test cùng isolate
không chứng minh giao dịch Firebase an toàn; cần test backend đồng thời riêng.

## Giao diện HHL Stay

Danh mục demo hiện có 14 homestay tại 14 điểm đến: Hà Nội, Sa Pa, Ninh Bình,
Hạ Long, Huế, Đà Nẵng, Hội An, Quy Nhơn, Nha Trang, Đà Lạt,
TP. Hồ Chí Minh, Vũng Tàu, Cần Thơ và Phú Quốc. Ở Khám phá, chọn miền rồi
chọn thành phố; hàng chip lọc nhanh Wi-Fi, bếp, hồ bơi, điều hòa, bãi đỗ xe
hoặc giá tốt. Có thể tìm theo tên, khu vực hoặc tiện nghi, lọc ngân sách,
số khách, ngày còn phòng và sắp xếp theo giá. Tất cả địa chỉ, nơi ở và giá
trong danh mục là dữ liệu minh họa, không phải chỗ ở đang kinh doanh.
Dữ liệu demo đã lưu trên máy được nâng cấp khi mở bản mới, giữ các thay đổi cũ.

Bản thiết kế mới: [nguồn tham khảo, chức năng và ảnh minh họa](thiet-ke-giao-dien.md).
Chủ nhà mở **Tổng quan → Lịch phòng** để xem tình trạng từng đêm.
Khách có thể chọn ngày/số khách ở Khám phá, dùng bộ lọc và sắp xếp theo giá;
ngày/số khách được giữ khi chuyển sang đặt phòng. Trước khi gửi yêu cầu,
app hiển thị bước kiểm tra tên phòng, ngày ở, số khách và tổng tiền.
Ảnh chụp tham khảo có nguồn trong [danh sách ảnh](nguon-anh.md); không xác nhận đó là ảnh của homestay mẫu.

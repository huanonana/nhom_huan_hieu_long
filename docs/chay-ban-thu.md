# Ứng dụng quản lý Homestay HHL

## Đã triển khai

- Kiến trúc tách model, repository, state (Riverpod), màn hình và router (go_router).
- Khám phá 14 homestay và phòng demo ở 14 điểm đến Việt Nam. Tìm kiếm gọn mở
  bảng chọn điểm đến/ngày/số khách; banner và ảnh thẻ chỗ ở có thể vuốt.
- Tìm theo tên/khu vực; lọc thành phố, tiện nghi, sức chứa, giá tối đa và ngày ở.
- Xem homestay/phòng, chọn ngày, nhập tên khách và ghi chú, xem giá trước khi gửi.
- Kiểm tra ngày, số khách, 1–30 đêm, không trùng khoảng ở, giữ đơn chờ 24 giờ.
- Admin demo xem và xử lý các đơn của hệ thống; Khách xem đơn của mình và hủy khi còn chờ. Admin duyệt/từ chối,
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
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8081
```

1. Mở app; mặc định vào **Admin → Tổng quan quản trị**. Thêm/sửa homestay, phòng,
   duyệt đơn và mở lịch phòng từ thanh điều hướng.
2. Để thử luồng khách, vào **Tài khoản → Khách đặt phòng**. Chọn
   **Nhà Bên Đồi → Xem phòng**, chọn ngày, nhập tên và gửi yêu cầu.
3. Chuyển về **Tài khoản → Quản trị viên → Quản lý** rồi vào **Đơn đặt**,
   tìm đơn và chọn **Duyệt đơn**.
4. Chuyển lại **Khách đặt phòng → Đơn đặt** để thấy trạng thái và QR. Sao chép nội dung mã; chuyển vai trò Admin, vào **Đơn đặt → Xác minh mã & nhận phòng** và dán mã. Khi trả phòng xong, khách có thể đánh giá.
5. Thử đặt cùng phòng/cùng ngày: ứng dụng báo không còn trống.
6. Muốn thử nhận/trả phòng, đặt ngày nhận là hôm nay. Đơn đã xác nhận
   chỉ được nhận trong khoảng lưu trú, không nhận trước ngày và không nhận từ ngày trả.

Phòng thông xanh có sẵn một đơn mẫu từ ngày hiện tại +2 đến +4 để kiểm tra
lọc phòng trống. Bộ đếm thời hạn được cập nhật mỗi phút và kiểm tra lại khi thao tác.

7. Vào **Quản lý → Tổng quan quản trị**, thêm homestay rồi thêm phòng. Homestay chỉ xuất hiện ở Khám phá khi có phòng đang mở phù hợp bộ lọc.
8. Mở menu thao tác bên phòng để sửa giá, sức chứa hoặc bảo trì. Tải lại app; app trở về Admin và dữ liệu demo vẫn được giữ trên máy.

## Phần chưa triển khai

Chưa có Firebase/Auth thật, dữ liệu máy chủ/đa thiết bị, phân quyền Admin phía máy chủ,
thanh toán/tiền thực thu, PDF, FCM, ảnh xác thực của homestay và bản đồ thật.
Mã QR hiện là mã demo tạo từ ID đơn, chưa có token ngẫu nhiên, máy quét tích hợp hay xác minh qua máy chủ.
Không nhập dữ liệu nhạy cảm vào bản thử. Tải lại cùng trình duyệt/địa chỉ sẽ đọc dữ liệu đã lưu; xóa dữ liệu trình duyệt hoặc gỡ app có thể làm mất dữ liệu demo. Chỉ thử trên một tab tại một thời điểm, chưa hỗ trợ đồng bộ nhiều tab.
Chuyển vai trò chỉ là công cụ thử nghiệm, không thay thế Security Rules.

Xem [đặc tả bổ sung](dac-ta-app.md) về quy tắc nghiệp vụ và transaction Firebase.
Android đã chuyển từ Gradle/Flutter apply-script cũ sang plugins DSL và build
APK debug thành công. Chưa cài/chạy thiết bị; iOS chưa kiểm tra.

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Đây là bản debug để thử,
chưa phải bản ký phát hành. Xem [kết quả kiểm thử](kiem-thu-ban-dau.md).

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

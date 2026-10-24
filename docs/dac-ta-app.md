# Đặc tả triển khai Homestay HHL

## Đánh giá đề cương

Đề cương đủ phạm vi một đồ án nhóm 3 người. Guest, Host, Admin là ba phân hệ;
không nên triển khai QR, báo cáo, thông báo trước khi đặt phòng và phân quyền đúng.
Ảnh tuần 1 chỉ là tài liệu thiết lập môi trường, không phải thiết kế giao diện.

## Các điểm bổ sung / quyết định ban đầu

1. **Hủy đơn:** Guest chỉ tự hủy `pending`. Sau xác nhận phải gửi yêu cầu và
   Host xử lý trước ngày nhận phòng, lưu lý do. Sơ đồ gốc cho hủy confirmed
   nhưng mô tả Guest không cho; bản đầu theo quy định chặt hơn. Chưa thu phí hủy.
2. **Đơn chờ duyệt:** giữ phòng 24 giờ; hết hạn chuyển `expired`, giải phóng lịch.
   Thời gian này là giả định ban đầu, có thể đổi theo yêu cầu của nhóm.
3. **Phòng:** một document là một phòng vật lý; `type` chỉ phân loại. Không dùng
   một document đại diện nhiều phòng mà chưa có mô hình số lượng tồn.
4. **Ngày ở:** ngày nhận bao gồm, ngày trả không bao gồm `[checkIn, checkOut)`.
   Cho phép khách sau nhận đúng ngày khách trước trả. Ngày nghiệp vụ dùng
   `Asia/Ho_Chi_Minh`, lưu ngày dạng YYYY-MM-DD; timestamp sự kiện dùng UTC.
   Giới hạn bản đầu tối đa 30 đêm/đơn, số khách nguyên dương và không quá sức chứa.
5. **Giá:** tiền nguyên VND, lưu `pricePerNightSnapshot`, `roomNameSnapshot`,
   số đêm, giảm giá/phụ phí nếu có và tổng tiền do máy chủ tính. Bản đầu không
   phụ phí, không cổng thanh toán: thanh toán tại homestay.
6. **Doanh thu:** tổng giá trị booking khác tiền thực thu. Thêm paymentStatus,
   amountPaid, paidAt và refunds; dashboard bản đầu chỉ gọi là giá trị đơn hoàn tất.
7. **Phân quyền:** người dùng mới luôn là Guest. Host được cấp quyền qua quy trình
   quản trị; Admin không được tự chọn trong đăng ký. Khoá tài khoản phải được
   kiểm tra ở máy chủ và rules; không chỉ ẩn nút trên app. Có thể mở rộng thành
   roles[] để Host đồng thời đặt phòng với tư cách Guest.
8. **Kiểm duyệt:** homestay cần moderationStatus (draft/pending/approved/rejected/
   suspended), publishedAt và lý do. Chỉ approved và hoạt động xuất hiện cho Guest.
9. **QR:** token ngẫu nhiên, thời hạn, gắn booking, kiểm tra quyền sở hữu của Host,
   trạng thái và ngày check-in; tiêu thụ một lần bằng transaction ở máy chủ.
   Không coi mã booking thuần là bí mật đủ để nhận phòng.
10. **Đánh giá:** đúng Guest của đơn, checked_out, 1 review/booking; document ID
    dùng bookingId. Cập nhật ratingAvg/ratingCount phía máy chủ. Favorite ID
    xác định bởi userId + homestayId; chỉ chủ sở hữu được ghi.
11. **Xóa dữ liệu:** homestay/phòng có đơn lịch sử chỉ ẩn/soft-delete; không
    xóa dây chuyền lịch sử booking. Bảo trì phải xét các đơn tương lai đang giữ phòng.
12. **Thông báo:** token theo thiết bị, inbox, đánh dấu đọc và server timestamp;
    FCM chỉ báo có sự kiện, không là nguồn dữ liệu duy nhất. Gửi sau commit thành công.
13. **Chất lượng:** loading/error/empty, retry, chống bấm gửi hai lần, phân trang,
    tối ưu ảnh, validation đầu vào, log chuyển trạng thái và kiểm thử phân quyền.
14. **Thống kê:** cắt số đêm theo kỳ báo cáo; mẫu số loại trừ ngày phòng bảo trì.
    Không tính đơn từ chối/hủy/hết hạn vào tỷ lệ lấp đầy.

## Lỗi trong transaction mẫu và phương án Firebase

`tx.get(roomRef)` không tự tạo một khoá ứng dụng đáng tin cậy trên Flutter.
Query `.collection('bookings').get()` ngoài `tx` không thuộc tập đọc transaction.
Hai request có thể cùng thấy phòng trống rồi ghi hai document booking khác nhau.

Thiết kế dự kiến: Callable Cloud Function `createBooking` nhận roomId, ngày,
số khách và idempotencyKey; lấy guestId từ auth. Trong **một transaction**:

- Đọc tài khoản, homestay, phòng, idempotency record và tất cả document
  `roomNights/{roomId_YYYY-MM-DD}` trong khoảng ở (đọc xong mới ghi).
- Xác minh người dùng active, homestay approved, phòng active, giá/sức chứa;
  từng đêm chưa giữ hoặc hold đã hết hạn theo server time.
- Ghi booking, các night lock và idempotency record trong cùng transaction.
- Khi duyệt, kiểm tra hold còn hiệu lực và quyền Host; chuyển hold thành booking.
  Khi hủy/từ chối/hết hạn, chỉ xóa lock nếu lock còn trỏ tới chính booking đó.
- Thao tác check-in/out, QR, tiền, vai trò và thống kê nhạy cảm cũng đi qua server.
  Client không có quyền ghi trực tiếp night lock, tổng tiền hay nâng vai trò.

Cần Security Rules + Storage Rules, Firestore indexes, test với Emulator và
test 2 request đồng thời trước khi dùng dữ liệu thật. TTL chỉ dọn document trễ,
không dùng TTL làm điều kiện duy nhất quyết định phòng trống.

Tham khảo: https://firebase.google.com/docs/firestore/manage-data/transactions
và https://firebase.google.com/docs/firestore/transaction-data-contention

## Schema cần thêm

- users: roles/role, updatedAt, disabledAt; subcollection devices.
- homestays: moderationStatus, timezone, updatedAt, deletedAt, rejectionReason.
- rooms: roomNumber, updatedAt, deletedAt; maintenanceBlocks theo khoảng ngày.
- bookings: snapshot tên phòng/giá, currency, expiresAt, updatedAt, rejectionReason,
  cancellationReason, cancelledBy, paymentStatus, amountPaid, checkedInAt,
  checkedOutAt, idempotencyKey; statusEvents (actor, old/new status, timestamp).
- roomNights: roomId, stayDate, bookingId, holdUntil hoặc confirmed.
- notifications, paymentEvents/refunds, booking QR token records.

## Giai đoạn và tiêu chí hoàn thành

1. **Bản demo luồng chính — đã có.** Riverpod + go_router, model nghiệp vụ,
   repository, dữ liệu mẫu, khám phá/đặt/quản trị và kiểm thử ngày, sức chứa,
   trùng lịch, review, tài chính và trạng thái.
2. **Firebase lớp — đã tích hợp một phần.** Firebase Auth email/mật khẩu, hồ sơ
   người dùng, Firestore document store và role-based Rules đã triển khai; web
   Firebase và APK debug build thành công. Rules Emulator có 6 nhóm test tự động,
   chạy lại đạt ngày 24/10/2026. Auth/profile smoke test trước đó đã qua; chưa có
   E2E đủ các luồng đặt phòng, host, tài chính và nhân viên sau lần siết Rules.
3. **Hardening production — còn thiếu.** Rules lớp hiện tách quyền khách/quản lý,
   nhưng mô hình vẫn chỉ có một vai trò host, không có phân tách nhiều chủ sở hữu;
   thêm transaction đặt phòng, retry/offline queue, đồng bộ đa thiết bị, xác minh
   ảnh và kiểm thử Firebase Emulator/concurrency.
4. **Dịch vụ thật — ngoài phạm vi demo.** Thanh toán/đối soát, FCM, QR ký phía server,
   bản đồ và quy trình kiểm duyệt homestay.

## Giới hạn bản thử hiện tại

Local mode lưu dữ liệu demo trên thiết bị. Firebase mode dùng Firebase Authentication
và Firestore cho các luồng được tích hợp; Security Rules giới hạn đơn theo UID,
chặn tự nâng quyền và dành dữ liệu vận hành cho host. Đây vẫn là mô hình lớp một
chủ homestay, chưa có transaction máy chủ chống đặt trùng đồng thời. Không dùng dữ
liệu khách thật. QR vẫn là demo; thanh toán/đối soát và FCM chưa có.
Không công bố bản thử này là hệ thống đặt phòng production.
Android đã nâng cấu hình Gradle và build APK debug; còn cần thử trên thiết bị.

# Ghi công ảnh homestay

App có 14 album, mỗi album gồm 3 ảnh chỗ nghỉ. Mỗi ảnh được lưu cục bộ theo tên địa điểm trong `assets/images/homestays/`.

Toàn bộ ảnh mới được tải từ thư viện ảnh miễn phí Pexels. Với từng ảnh, `location_photo_data.dart` lưu đường dẫn asset, mô tả ngắn, tác giả, liên kết trang ảnh Pexels và trạng thái xác thực địa điểm. Gallery hiển thị tên tác giả và liên kết nguồn để người xem có thể kiểm tra. Quy định sử dụng: [Pexels License](https://www.pexels.com/license/).

`verified: true` chỉ dành cho ảnh có thông tin nguồn xác nhận đúng khu vực. Ảnh còn lại dùng `verified: false` và ghi “Ảnh tham khảo, chưa xác nhận đúng địa điểm”. Các homestay trong app là dữ liệu demo; không ảnh nào được khẳng định là ảnh của chính căn đang rao.

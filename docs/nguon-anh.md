# Nguồn ảnh trong HHL Stay

Album demo sử dụng 42 ảnh phòng nghỉ/không gian lưu trú khác nhau, gồm 3 ảnh cho mỗi homestay mẫu. Tệp ảnh được lưu cục bộ tại `assets/images/homestays/` để app chạy được khi offline.

Ảnh được tải từ [Pexels](https://www.pexels.com/), nơi ghi ảnh là miễn phí sử dụng theo [giấy phép Pexels](https://www.pexels.com/license/). Tác giả và trang nguồn của từng ảnh được ghi ngay trong [danh sách ảnh](../lib/core/widgets/location_photo_data.dart) và hiện trong gallery. Ảnh demo không khẳng định thuộc homestay đang rao. Chỉ ảnh có địa điểm nguồn được xác nhận mới đặt `verified: true`; các ảnh tham khảo còn lại được đánh dấu `verified: false`.

Ảnh được tuyển lại theo tiêu chí ảnh phòng sáng, nhìn rõ giường và bố cục, có thêm ban công/góc sinh hoạt ở một số bộ ảnh. Album ưu tiên trải nghiệm xem chỗ nghỉ; ảnh tham khảo không đại diện cho tiện nghi hay căn phòng thực tế của từng địa điểm.

# Thiết kế HHL Stay — 27/09/2026

## Tham khảo

- Go2Joy: https://go2joy.vn/vi-vn — tìm địa điểm, ngày ở, thao tác đặt phòng nổi bật.
- Dayladau: https://dayladau.com — lọc nhanh địa điểm/tiện nghi, tập trung danh sách nơi ở.

HHL dùng bố cục riêng: nền trắng, điểm nhấn cam san hô, thẻ ảnh lớn, giá theo đêm,
thanh ngày/số khách dùng chung. Không dùng logo, nội dung ưu đãi, ảnh khách sạn
hoặc điểm đánh giá từ hai dịch vụ. Chỉ hỗ trợ theo đêm; chưa có đặt theo giờ.

## Chức năng của bản giao diện mới

- Bộ lọc dạng bảng trượt: ngân sách, tiện nghi, đặt lại và áp dụng.
- Sắp xếp gợi ý/giá tăng/giá giảm; giá trên thẻ là giá thấp nhất của phòng phù hợp bộ lọc.
- Ngày ở và số khách được truyền từ khám phá qua chi tiết đến đặt phòng.
- Xem ảnh phóng lớn, yêu thích trên thẻ và chi tiết.
- Chi tiết phòng báo hết chỗ/không đủ sức chứa/bảo trì; nút chọn phòng cố định cuối trang.
- Xem lại chuyến đi và tổng tiền trước khi gửi yêu cầu.
- Chủ nhà có lịch phòng theo ngày, xem đơn đang chiếm phòng, ngày trước/sau/chọn ngày.
- Tài khoản có thống kê chuyến đi/yêu thích, hướng dẫn đặt phòng và chuyển vai trò demo.

## Ảnh minh họa

Được tạo bằng built-in image_gen theo skill imagegen, lưu trong repo:
- `assets/images/pine.png`
- `assets/images/sea.png`
- `assets/images/garden.png`

Đây là ảnh AI của nơi ở hư cấu, được ghi nhãn trong app. Không phải ảnh quảng cáo
cho một homestay có thật. Không có bước tải ảnh đối thủ hay chuyển sang CLI/API.

### Prompt pine.png
Use case: photorealistic-natural. Asset type: landscape editorial room photograph for Vietnamese homestay booking demo app. Generate one warm minimalist boutique bedroom in Da Lat: low oak bed with white linen, terracotta cushion, woven pendant, broad floor-to-ceiling window overlooking misty pine trees, inviting morning sunlight, real tactile materials, professional architectural travel photography. Wide 3:2 composition, whole bedroom, no people, no lettering, no logos, no watermark. This is a fictional demonstration homestay.

### Prompt sea.png
Use case: photorealistic-natural. Asset type: landscape travel accommodation photo for fictional Vietnamese homestay demo. One airy coastal boutique bedroom in Da Nang, white linen bed, pale oak furniture, sand-colored limewash walls, blue cushion, sheer curtains moving beside open balcony with distant ocean, lush palm leaves, gentle daylight, understated editorial architecture photography. Wide 3:2 framing, no people, no typography, no logo or watermark.

### Prompt garden.png
Use case: photorealistic-natural. Asset type: landscape travel accommodation photograph for a fictional Hoi An garden homestay app demo. Elegant Vietnamese courtyard bedroom, warm ochre plaster, timber sliding doors opening to lush green tropical garden and a little reflecting pool, rattan chair, white linen double bed, pottery, late afternoon sun, tasteful boutique interior, realistic architectural editorial photograph, wide 3:2 composition. No people, no text, no logo, no watermark.

Cập nhật theo yêu cầu bám Go2Joy: điểm nhấn cam; lựa chọn Qua đêm đặt một đêm và Theo ngày mở lịch 1–30 đêm. Không hiển thị lựa chọn theo giờ khi chưa có nghiệp vụ hỗ trợ.

## Cập nhật 28/09/2026 — ảnh chụp thật
- Bộ ảnh hiện dùng là 42 JPEG chỗ nghỉ tham khảo theo 14 homestay mẫu từ Wikimedia Commons; mỗi căn có 3 ảnh riêng, xem [nguồn và giấy phép](nguon-anh-dia-danh.md). Nội dung prompt AI bên trên chỉ ghi lại phiên bản thiết kế cũ.
- Album mỗi homestay gồm 3 ảnh: vuốt ngang, nút trước/sau, ảnh thu nhỏ, mở toàn màn hình và phóng to. Nguồn ảnh hiển thị trong album.
- Nút Tìm phòng ngay đưa đến kết quả; lối tắt Ấm cúng / Có hồ bơi / Giá dễ chịu thực sự áp dụng bộ lọc.
- Giữ đặt theo đêm, không thêm lựa chọn theo giờ khi dữ liệu chưa hỗ trợ.


## Câu 5 — mẫu dashboard StudySmart

Nhóm chọn mẫu StudySmart trong ảnh tham chiếu được cung cấp: lời chào và trạng thái người dùng ở đầu trang, các thẻ thống kê, một hành động chính, danh sách thao tác nhanh và thanh điều hướng dưới. Trang chủ HHL Stay chuyển các thành phần này thành lời chào khách, số chỗ nghỉ/điểm đến, nút tìm chỗ nghỉ, các lối tắt đến khám phá/đơn đặt/yêu thích/trợ lý, danh sách điểm đến và thanh điều hướng hiện có. Màn hình chỉ áp dụng cho viewport điện thoại (rộng dưới 600 px); giao diện desktop và các luồng đặt phòng giữ nguyên. Ảnh triển khai được chụp từ localhost tại 393 × 852 CSS px ở `output/report/HHL_Stay_home_studysmart_localhost.png`; ảnh so sánh mẫu và kết quả nằm ở `output/report/StudySmart_HHL_Stay_so_sanh.png` và Hình G.15 trong báo cáo.

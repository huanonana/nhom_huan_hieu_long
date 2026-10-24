# Hồ sơ nộp bài lớn Phenikaa — HHL Stay

Tài liệu này tách phần đã có trong code/báo cáo khỏi thông tin nhóm phải tự xác nhận. Các mục phân tích và thiết kế là nội dung báo cáo; chỉ các mục ghi “hiện thực” mới là chức năng cần chạy trong app.

## Đối chiếu yêu cầu trên bảng

| Yêu cầu | Bằng chứng hiện có | Còn cần làm trước khi nộp |
| --- | --- | --- |
| Project User Stories | 24 stories trong báo cáo: 14 Guest và 10 Host | Nếu nhóm có 4 người, bảo đảm tổng ít nhất 16; nhóm kiểm tra tiêu chí chấp nhận theo đúng nghiệp vụ đã thống nhất. |
| Phân tích đối tượng, quan hệ và hoạt động | Actor, domain model, từ điển dữ liệu và mô tả luồng trong báo cáo | Nhóm xác nhận thuật ngữ và ranh giới nghiệp vụ với giảng viên. |
| Class Diagram | Class diagram HHL Stay trong báo cáo | Đối chiếu sơ đồ với model hiện tại trước khi in. |
| Sequence/Activity diagrams | 3 Activity + 4 Sequence (7 sơ đồ quy trình) | Giải thích được mỗi sơ đồ trong phần trình bày. |
| Screens, wireframes, mockup và Flow of Work | 14 ảnh app chụp từ localhost trong viewport trình duyệt dọc 393×852 CSS px (không dùng Medium Phone), 6 wireframe mobile PNG, 7 luồng và sơ đồ làm việc; Câu 5 chọn mẫu StudySmart từ ảnh tham chiếu người dùng cung cấp, đã hiện thực cấu trúc dashboard trên Trang chủ HHL Stay và có ảnh so sánh ở Hình G.15 trong báo cáo | Có thể bổ sung URL Canvas gốc nếu giảng viên yêu cầu truy nguyên mẫu; bản tham chiếu nhóm dùng đã được đưa vào báo cáo. |
| Implement stories | Các luồng Flutter, 103 test Flutter, 4 test tiện ích proxy local, Web local và Android release build | Demo trực tiếp các luồng đã chọn, nêu giới hạn demo. |
| Firebase/DB/ORM | Firebase Auth + Firestore trong build bật `HHL_USE_FIREBASE=true`; document mapper và Rules theo vai trò; 8 nhóm emulator kiểm tra Auth, hồ sơ, guest booking, host xác nhận đơn/ghi chi phí, quyền truy cập và hủy đơn | Đã kiểm tra end-to-end trên Auth/Firestore Emulator; chưa chạy acceptance end-to-end trên Firebase project thật. Không dùng dữ liệu khách thật. |
| Test và kiểm định | `flutter analyze` sạch; 103/103 unit/widget/repository tests; 4/4 test proxy local; Auth + Firestore Emulator 8/8 nhóm qua; `npm audit` 0 lỗ hổng. Firebase Web release và Android Firebase debug APK build thành công. Một câu hỏi Gemini nhận phản hồi live trên localhost:8083. Ảnh app trong báo cáo chụp localhost ở viewport 393×852 CSS px. | Emulator không thay thế kiểm thử project thật hoặc Android device. Gemini mới smoke-test một prompt trên localhost; chưa kiểm thử Android/quota đầy đủ. Chưa kiểm thử đồng bộ đa thiết bị, đặt đồng thời, thanh toán thật hoặc production. |
| Báo cáo, demo, GitHub và đóng góp | Báo cáo DOCX/PDF; video demo 01:14 nằm trong repo; GitHub repo công khai; bảng nhiệm vụ và tỷ lệ đã thống nhất: Hiếu 34%, Huấn 33%, Long 33%. | Sau push, kiểm tra link video mở được khi chưa đăng nhập; nhóm xác nhận commit/repo đúng phiên bản nộp và rà bảng phân công. |
| Commit và điểm danh | Git history trong repo | Mỗi thành viên rà commit của mình và xác nhận yêu cầu điểm danh/chữ ký nộp. |

## Thông tin nhóm cần xác nhận

1. Sĩ số chính thức (3 hay 4 người) và danh sách đủ họ tên/MSSV. Bìa ghi Phạm Văn Huấn — `23010331`, Nguyễn Hữu Lê Hiếu — `23010985`, Nguyễn Hải Long — `23010872` (theo thông tin người dùng cung cấp).
2. Giảng viên hướng dẫn: TS. Nguyễn Lệ Thu.
3. Phân công đã được điền trong báo cáo theo tỷ lệ nhóm thống nhất: Nguyễn Hữu Lê Hiếu 34%, Phạm Văn Huấn 33%, Nguyễn Hải Long 33%. Nhóm đối chiếu nhiệm vụ với phần việc thực tế và rà thông tin MSSV trước khi in. `git shortlog` là lịch sử commit, không thay thế bảng phân công.
4. Câu 5: đã chọn mẫu StudySmart (dashboard học tập) trong ảnh tham chiếu do người dùng cung cấp; màn Trang chủ HHL Stay đã được dựng theo cấu trúc lời chào, thẻ thống kê, hành động chính, danh sách lối tắt và điều hướng. Bằng chứng so sánh mẫu với màn localhost nằm ở Hình G.15 trong báo cáo.
5. Link video demo dưới 8 phút: video `docs/demo-video/HHL_Stay_demo.mp4` dài 01:14. Báo cáo liên kết tới tệp trong repo công khai; sau push, mở liên kết bằng cửa sổ riêng chưa đăng nhập để xác nhận quyền xem.
6. Link GitHub và commit phải trỏ tới đúng repository/phiên bản được nộp: https://github.com/huanonana/nhom_huan_hieu_long. Xác nhận SHA commit cuối sau khi push bản nộp.
7. Mỗi sinh viên cần một bản in riêng có tên và MSSV cá nhân trên bìa; nộp bản cứng và ký danh sách theo hạn cô đưa.

## File sản phẩm

- Báo cáo: `output/report/Bao_cao_do_an_HHL_Stay.docx` và `output/report/Bao_cao_do_an_HHL_Stay.pdf`; bản PDF cuối khổ A4 dài 48 trang; đã render đủ trang và rà contact sheet sau khi cập nhật mục lục. Đã tạo bìa riêng cho Hiếu, Huấn và Long; người nộp rà chính tả tên/MSSV lần cuối trước khi in.
- Bản chạy mới: `build/web` giữ bản local demo; Firebase Web release build ở `tmp/firebase-web-check`; Android Firebase debug APK build tại `build/app/outputs/flutter-apk/app-debug.apk`. Android Firebase release chưa build trong lượt này. APK debug chưa cài lên thiết bị; báo cáo dùng ảnh localhost tại viewport điện thoại.
- Wireframe: `docs/wireframes/01-home.png` đến `docs/wireframes/06-admin-dashboard.png`.
- Hướng dẫn chạy: [chay-ban-thu.md](chay-ban-thu.md); chế độ Firebase: [firebase-mode.md](firebase-mode.md).
- Firestore Rules: [firestore.rules](firestore.rules), có bộ test tự động ở `tool/firestore-rules-tests/`; thay đổi ID review cần triển khai lên project lớp trước khi kiểm tra luồng Firebase thật.

Thời hạn trên đề được đọc là bản cứng trước 17:00 và PDF trước 23:59 ngày 03/11/2026. Nhóm cần kiểm tra lại trên trang môn học nếu giảng viên có cập nhật.

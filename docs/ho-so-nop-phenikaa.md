# Hồ sơ nộp bài lớn Phenikaa — HHL Stay

Tài liệu này tách phần đã có trong code/báo cáo khỏi thông tin nhóm phải tự xác nhận. Các mục phân tích và thiết kế là nội dung báo cáo; chỉ các mục ghi “hiện thực” mới là chức năng cần chạy trong app.

## Đối chiếu yêu cầu trên bảng

| Yêu cầu | Bằng chứng hiện có | Còn cần làm trước khi nộp |
| --- | --- | --- |
| Project User Stories | 24 stories trong báo cáo: 14 Guest và 10 Host | Nếu nhóm có 4 người, bảo đảm tổng ít nhất 16; nhóm kiểm tra tiêu chí chấp nhận theo đúng nghiệp vụ đã thống nhất. |
| Phân tích đối tượng, quan hệ và hoạt động | Actor, domain model, từ điển dữ liệu và mô tả luồng trong báo cáo | Nhóm xác nhận thuật ngữ và ranh giới nghiệp vụ với giảng viên. |
| Class Diagram | Class diagram HHL Stay trong báo cáo | Đối chiếu sơ đồ với model hiện tại trước khi in. |
| Sequence/Activity diagrams | 3 Activity + 4 Sequence (7 sơ đồ quy trình) | Giải thích được mỗi sơ đồ trong phần trình bày. |
| Screens, wireframes, mockup và Flow of Work | 14 ảnh app chụp dọc từ Medium Phone (720×1600 hoặc 1080×2400), 5 ảnh kiểm thử luồng khách–admin mới, 6 wireframe mobile PNG, 7 luồng và sơ đồ làm việc | Bốn link mẫu Canvas trong đề trả `Unauthorized` khi kiểm tra ngày 24/10/2026. Cần xác nhận mẫu đã chọn và lấy ảnh/export trước khi làm câu 5. |
| Implement stories | Các luồng Flutter, 101 test tự động, web local và Android release build | Demo trực tiếp các luồng đã chọn, nêu giới hạn demo. |
| Firebase/DB/ORM | Firebase Auth + Firestore trong build bật `HHL_USE_FIREBASE=true`; document mapper và Rules theo vai trò; 6 nhóm Rules Emulator kiểm tra guest/host, booking, review, finance và staff | Chưa chạy đầy đủ Firebase E2E trên project thật cho booking/host/finance/staff. Không dùng dữ liệu khách thật. |
| Test và kiểm định | `flutter analyze` sạch; 101/101 unit/widget tests; Rules Emulator 6/6 nhóm qua; Web local và Android release APK đã build ngày 24/10/2026. Gemini trả lời câu hỏi thử trên localhost. APK local release mở được trên Medium Phone; đã smoke-test các màn quản trị Tổng quan, Tài chính, Buồng phòng và Đơn đặt. Lỗi chồng chữ tại trang Tài chính mobile đã được sửa và kiểm tra lại. | Kiểm thử bằng dữ liệu local demo, không phải Firebase E2E; chưa xác nhận đồng bộ liên thiết bị, thanh toán thật, giao dịch đồng thời, Gemini live trên APK hoặc production. |
| Báo cáo, demo, GitHub và đóng góp | Báo cáo DOCX/PDF; video demo 01:14 nằm trong repo; GitHub repo công khai; bảng nhiệm vụ và tỷ lệ đã thống nhất: Hiếu 34%, Huấn 33%, Long 33%. | Sau push, kiểm tra link video mở được khi chưa đăng nhập; nhóm xác nhận commit/repo đúng phiên bản nộp và rà bảng phân công. |
| Commit và điểm danh | Git history trong repo | Mỗi thành viên rà commit của mình và xác nhận yêu cầu điểm danh/chữ ký nộp. |

## Thông tin nhóm cần xác nhận

1. Sĩ số chính thức (3 hay 4 người) và danh sách đủ họ tên/MSSV. Bìa hiện ghi Phạm Văn Huấn — `23010331`, Nguyễn Hữu Lê Hiếu — `23010985`, Nguyễn Hải Long — `2301872`; mã MSSV của Long có độ dài khác hai mã còn lại nên cần đối chiếu thẻ sinh viên, không tự sửa theo phỏng đoán.
2. Giảng viên hướng dẫn: TS. Nguyễn Lệ Thu.
3. Phân công đã được điền trong báo cáo theo tỷ lệ nhóm thống nhất: Nguyễn Hữu Lê Hiếu 34%, Phạm Văn Huấn 33%, Nguyễn Hải Long 33%. Nhóm đối chiếu nhiệm vụ với phần việc thực tế và rà thông tin MSSV trước khi in. `git shortlog` là lịch sử commit, không thay thế bảng phân công.
4. Mẫu giao diện cụ thể trên Canvas mà nhóm chọn cho yêu cầu số 5 (tên file/màn hình và ảnh hoặc export truy cập được). Bốn link đề bài hiện trả `Unauthorized` từ phiên kiểm tra này. Sáu wireframe HHL Stay là thiết kế của nhóm, không chứng minh đã hiện thực một mẫu Canvas. Câu 5 vẫn chưa hoàn tất cho tới khi chọn mẫu và có ảnh tham chiếu.
5. Link video demo dưới 8 phút: video `docs/demo-video/HHL_Stay_demo.mp4` dài 01:14. Báo cáo liên kết tới tệp trong repo công khai; sau push, mở liên kết bằng cửa sổ riêng chưa đăng nhập để xác nhận quyền xem.
6. Link GitHub và commit phải trỏ tới đúng repository/phiên bản được nộp: https://github.com/huanonana/nhom_huan_hieu_long. Xác nhận SHA commit cuối sau khi push bản nộp.
7. Mỗi sinh viên cần một bản in riêng có tên và MSSV cá nhân trên bìa; nộp bản cứng và ký danh sách theo hạn cô đưa.

## File sản phẩm

- Báo cáo: `output/report/Bao_cao_do_an_HHL_Stay.docx` và `output/report/Bao_cao_do_an_HHL_Stay.pdf` (92 trang; Phụ lục G có 14 ảnh giao diện điện thoại dọc ở trang 62–75; Phụ lục I ghi nhận kiểm tra Medium Phone ở trang 82–86; mục lục đã khớp bản PDF cuối). Bản bìa cá nhân Hiếu và Huấn nằm trong `output/report/personal/`; bản Long cần MSSV đã xác nhận.
- Bản chạy mới: `build/web` được build ở local mode; APK trong `output/builds/` gồm local debug, Firebase debug và local release. Firebase release chưa hoàn tất do giới hạn RAM trên máy này.
- Wireframe: `docs/wireframes/01-home.png` đến `docs/wireframes/06-admin-dashboard.png`.
- Hướng dẫn chạy: [chay-ban-thu.md](chay-ban-thu.md); chế độ Firebase: [firebase-mode.md](firebase-mode.md).
- Firestore Rules: [firestore.rules](firestore.rules), có bộ test tự động ở `tool/firestore-rules-tests/`; thay đổi ID review cần triển khai lên project lớp trước khi kiểm tra luồng Firebase thật.

Thời hạn trên đề được đọc là bản cứng trước 17:00 và PDF trước 23:59 ngày 03/11/2026. Nhóm cần kiểm tra lại trên trang môn học nếu giảng viên có cập nhật.

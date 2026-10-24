# Hồ sơ nộp bài lớn Phenikaa — HHL Stay

Tài liệu này tách phần đã có trong code/báo cáo khỏi thông tin nhóm phải tự xác nhận. Các mục phân tích và thiết kế là nội dung báo cáo; chỉ các mục ghi “hiện thực” mới là chức năng cần chạy trong app.

## Đối chiếu yêu cầu trên bảng

| Yêu cầu | Bằng chứng hiện có | Còn cần làm trước khi nộp |
| --- | --- | --- |
| Project User Stories | 19 stories trong báo cáo: 12 Guest và 7 Host | Nếu nhóm có 4 người, bảo đảm tổng ít nhất 16; nhóm kiểm tra tiêu chí chấp nhận theo đúng nghiệp vụ đã thống nhất. |
| Phân tích đối tượng, quan hệ và hoạt động | Actor, domain model, từ điển dữ liệu và mô tả luồng trong báo cáo | Nhóm xác nhận thuật ngữ và ranh giới nghiệp vụ với giảng viên. |
| Class Diagram | Class diagram HHL Stay trong báo cáo | Đối chiếu sơ đồ với model hiện tại trước khi in. |
| Sequence/Activity diagrams | 3 Activity + 4 Sequence (7 sơ đồ quy trình) | Giải thích được mỗi sơ đồ trong phần trình bày. |
| Screens, wireframes, mockup và Flow of Work | 14 ảnh app, 6 wireframe mobile PNG, 7 luồng và sơ đồ làm việc | Bốn link mẫu Canvas trong đề trả `Unauthorized` khi kiểm tra ngày 24/10/2026. Cần xác nhận mẫu đã chọn và lấy ảnh/export trước khi làm câu 5. |
| Implement stories | Các luồng Flutter, 96 test tự động, web local và Android debug build | Demo trực tiếp các luồng đã chọn, nêu giới hạn demo. |
| Firebase/DB/ORM | Firebase Auth + Firestore trong build bật `HHL_USE_FIREBASE=true`; document mapper, rules và test smoke thật | Không dùng rules demo với dữ liệu khách thật; nếu cô yêu cầu emulator test hoặc quyền theo role, cần bổ sung riêng. |
| Test và kiểm định | `flutter analyze`, 96/96 unit/widget tests, Web build, local/Firebase Android debug APK và local release APK; Firebase APK mở được Explore trên Medium Phone | Lần build release gần nhất làm máy chủ gần cạn RAM; Android emulator hiện có System UI/Phone-service ANR dù HHL Stay vẫn render. Đây là giới hạn môi trường cần nêu khi demo; chưa có test giao dịch đồng thời hoặc production. |
| Báo cáo, demo, GitHub và đóng góp | Báo cáo DOCX/PDF; có video demo local ứng viên; Git remote đã cấu hình | Nhóm phải duyệt nội dung/thời lượng video, đưa link truy cập được, xác nhận commit/repo đúng phiên bản nộp và tỷ lệ đóng góp thật. |
| Commit và điểm danh | Git history trong repo | Mỗi thành viên rà commit của mình và xác nhận yêu cầu điểm danh/chữ ký nộp. |

## Thông tin nhóm cần xác nhận

1. Sĩ số chính thức (3 hay 4 người) và danh sách đủ họ tên/MSSV. Bìa hiện ghi Phạm Văn Huấn — `23010331`, Nguyễn Hữu Lê Hiếu — `23010985`, Nguyễn Hải Long — `2301872`; mã MSSV của Long có độ dài khác hai mã còn lại nên cần đối chiếu thẻ sinh viên, không tự sửa theo phỏng đoán.
2. Họ tên giảng viên hướng dẫn để điền lên bìa.
3. Phân công và phần trăm đóng góp theo công việc thực tế. Snapshot `git shortlog` hiện tại có 26 commit từ `lehiu1310`, 2 từ `Longsokiuu`, 1 từ `HUAN PHAM`; số commit không đại diện trực tiếp cho tỷ lệ đóng góp. Nhóm cần rà từng đầu việc/commit, xác nhận vai trò và tự thống nhất phần trăm.
4. Mẫu giao diện cụ thể trên Canvas mà nhóm chọn cho yêu cầu số 5 (tên file/màn hình và ảnh hoặc export truy cập được). Bốn link đề bài hiện trả `Unauthorized` từ phiên kiểm tra này. Sáu wireframe HHL Stay là thiết kế của nhóm, không chứng minh đã hiện thực một mẫu Canvas. Câu 5 vẫn chưa hoàn tất cho tới khi chọn mẫu và có ảnh tham chiếu.
5. Link video demo mà giảng viên mở được, dài dưới 8 phút. Có một video local ứng viên tại `output/demo-video/HHL_Stay_demo.mp4`; nhóm cần xem lại nội dung/thời lượng cuối, tải lên nơi chia sẻ được và điền URL vào báo cáo.
6. Link GitHub và commit phải trỏ tới đúng repository/phiên bản được nộp. Remote đã cấu hình nhưng workspace còn thay đổi chưa push; xác nhận sau khi đẩy bản cuối.
7. Mỗi sinh viên cần một bản in riêng có tên và MSSV cá nhân trên bìa; nộp bản cứng và ký danh sách theo hạn cô đưa.

## File sản phẩm

- Báo cáo: `output/report/Bao_cao_do_an_HHL_Stay.docx` và `output/report/Bao_cao_do_an_HHL_Stay.pdf`.
- Bản chạy mới: `build/web` được build ở local mode; APK trong `output/builds/` gồm local debug, Firebase debug và local release. Firebase release chưa hoàn tất do giới hạn RAM trên máy này.
- Wireframe: `docs/wireframes/01-home.png` đến `docs/wireframes/06-admin-dashboard.png`.
- Hướng dẫn chạy: [chay-ban-thu.md](chay-ban-thu.md); chế độ Firebase: [firebase-mode.md](firebase-mode.md).
- Rules demo: [../firestore.rules](../firestore.rules). Rules này đã triển khai lên project lớp để thử; không dùng cho dữ liệu thật.

Thời hạn trên đề được đọc là bản cứng trước 17:00 và PDF trước 23:59 ngày 03/11/2026. Nhóm cần kiểm tra lại trên trang môn học nếu giảng viên có cập nhật.

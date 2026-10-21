# Đối chiếu yêu cầu tuần 1

Kiểm tra ngày 24/09/2026 theo đề bài và ảnh minh họa được cung cấp.

| Yêu cầu | Kết quả |
|---|---|
| Nhóm 3–4 sinh viên | Có 3 thành viên; tên và MSSV trong README |
| Tên đề tài | Xây dựng ứng dụng quản lý homestay — Huấn, Hiếu, Long |
| Một repo chung | huanonana/nhom_huan_hieu_long |
| Quyền thành viên | huanonana: admin; lehiu1310, Longsokiuu: write (đã kiểm tra qua GitHub API) |
| Mời giảng viên | Chưa thấy trong danh sách collaborator đã chấp nhận; chủ repo cần kiểm tra cả lời mời đang chờ |
| Khung Flutter | Dự án chính tại gốc repo, Home của Homestay HHL và hộp thoại thông tin nhóm |
| Dev Container | Có Dockerfile, Flutter 3.35.2, extension Dart/Flutter và forward cổng 8080 |
| Kiểm thử Flutter | Phân tích mã không có lỗi; widget test đạt; build Web thành công |
| Demo Web trên máy | Đã mở Home và kiểm tra hộp thoại thành viên trên trình duyệt tại cổng 8081 (8080 đang được ứng dụng khác sử dụng) |
| Chạy container | Chưa xác minh: Docker Engine trên máy kiểm tra chưa phản hồi |
| Nộp LMS | Chưa xác minh; ảnh đề bài ghi bài đã khóa, cần kiểm tra trên hệ thống lớp |

## Những phần đã bổ sung

- Thông tin nhóm, tài khoản GitHub, hướng dẫn Codespaces/Dev Container và nội dung nộp bài.
- Màn hình Home riêng cho Homestay HHL; ảnh mẫu chỉ được dùng để đối chiếu thiết lập môi trường.
- Nâng ràng buộc Dart và web bootstrap để chạy với Flutter 3.35.2.
- Container cài Flutter từ repo chính thức, dùng phiên bản cố định thay cho image beta thả nổi.
- Cấu hình chạy web 8080 và loại trừ thư mục build/node_modules khỏi Git.
- Giữ lại bản mẫu cũ `homestay_app/`, ghi rõ không sử dụng cho bài tuần 1.

## Việc chủ repo/nhóm cần hoàn tất

1. Huấn kiểm tra/mời đúng tài khoản giảng viên (`lethunguyen` hoặc `nglthu`).
   Tài khoản Hiếu đang có quyền write, không có quyền quản trị collaborator.
2. Dựng Dev Container/Codespace và chụp minh chứng chạy thật theo README.
3. Nộp link repo, thông tin nhóm và ảnh minh chứng theo yêu cầu của lớp.

Ảnh `push.png` minh họa lỗi Git LFS của nhóm khác, không phải bằng chứng repo
này có lỗi đó. Không xóa hook Git để xử lý một lỗi chưa xảy ra ở repo này;
container có cài `git-lfs` để hỗ trợ môi trường dùng LFS.

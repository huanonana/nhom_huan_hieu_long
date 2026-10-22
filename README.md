# Xây dựng ứng dụng quản lý homestay — Huấn, Hiếu, Long

> Bản phát triển app sau tuần 1: xem [luồng chạy thử](docs/chay-ban-thu.md) và
> [đặc tả đã rà soát](docs/dac-ta-app.md). App hiện dùng dữ liệu demo lưu trên máy,
> có khám phá, đặt/duyệt đơn và chuyển vai trò thử nghiệm. Hướng dẫn tuần 1 bên
> dưới được giữ làm tài liệu lịch sử; màn hình Home đã được phát triển tiếp.

Bài thực hành tuần 1: lập nhóm, tạo repo chung và khung Flutter chạy trên web
bằng Dev Container/GitHub Codespaces.

## Thành viên

| Họ và tên | Mã sinh viên | GitHub |
|---|---|---|
| Phạm Văn Huấn | 23010331 | [huanonana](https://github.com/huanonana) |
| Nguyễn Hữu Lê Hiếu | 23010985 | [lehiu1310](https://github.com/lehiu1310) |
| Nguyễn Hải Long | 2301872 | [Longsokiuu](https://github.com/Longsokiuu) |

Repo chung: https://github.com/huanonana/nhom_huan_hieu_long

## Phạm vi tuần 1

Ứng dụng có màn hình Home riêng mang tên **Homestay HHL**, giới thiệu các
chức năng dự kiến và hộp thoại thông tin thành viên. Ảnh của giảng viên chỉ
minh họa cách thiết lập môi trường, không phải giao diện cần sao chép.
Chưa triển khai đăng nhập, phòng, đặt phòng, hóa đơn hay cơ sở dữ liệu.

**Dự án chính nằm ở thư mục gốc repo** (cùng cấp với README này).
Thư mục `homestay_app/` là bản khung cũ được giữ lại để tham khảo, không dùng
để chạy hoặc nộp bài tuần 1. Bộ phân tích mã bỏ qua bản cũ này.

## Chạy bằng GitHub Codespaces

1. Mở repo, chọn **Code → Codespaces → Create codespace on main**.
2. Chờ Dev Container dựng xong. Container cài Flutter **3.35.2 stable**
   (Dart 3.9.0), extension Dart/Flutter và tự chạy `flutter pub get`.
3. Trong terminal tại thư mục gốc repo:

   ```bash
   flutter --version
   dart --version
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
   ```

4. Mở tab **Ports**, chọn **Open in Browser** tại cổng **8080**.
   Có thể giữ cổng ở chế độ Private khi tự kiểm tra.
5. Kiểm tra màn hình Home; nhấn **Thông tin nhóm** để xem họ tên/MSSV và đóng hộp thoại.

Nếu Codespace đã tồn tại trước khi cập nhật cấu hình, chạy lệnh
**Dev Containers: Rebuild Container** từ Command Palette.
Có thể chọn cấu hình **Homestay Web (8080)** trong Run and Debug của VS Code.

## Chạy bằng Dev Container trên máy

Cần Docker Desktop đang chạy, VS Code và extension **Dev Containers**.
Clone repo, mở thư mục gốc bằng VS Code, chọn **Dev Containers: Reopen in Container**.
Sau đó thực hiện các lệnh Flutter ở trên.

Nếu dùng CLI theo tài liệu môn học, cài Node.js/npm rồi chạy ở máy chủ:

```bash
npm install -g @devcontainers/cli
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . flutter --version
devcontainer exec --workspace-folder . flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

CLI không tự mở cổng về máy như VS Code; dùng VS Code để forward cổng 8080.
Nếu chỉ muốn dựng image: `devcontainer build --workspace-folder .`.

Container tập trung vào **Flutter Web cho bài tuần 1**, chưa cài Android SDK
hay thiết lập iOS. Thư mục Android/iOS là khung gốc, chưa được xác nhận build.

## Chạy trực tiếp không qua container

Cài Flutter 3.35.2 stable, rồi chạy ở gốc repo:

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Mở http://localhost:8080.

## Chạy với tính năng AI

Các tính năng tóm tắt đánh giá, viết mô tả homestay và chatbot dùng Gemini API
với model `gemini-3.5-flash-lite`. Model này hiện có Free Tier; hạn mức miễn
phí có thể thay đổi và áp dụng giới hạn sử dụng. Tạo key mới trong
[Google AI Studio](https://aistudio.google.com/app/apikey), không cần nạp credit
cho Free Tier, rồi chạy app với:

```bash
flutter run --dart-define=GEMINI_API_KEY=xxx
```

Thay `xxx` bằng API key của bạn. Không commit hoặc chia sẻ key trong mã nguồn.
Không dán key vào chat, ảnh chụp màn hình hoặc lệnh có thể được lưu trong
terminal history. Nếu key bị lộ hoặc Google báo key bị chặn, hãy thu hồi key đó
và tạo key mới trong AI Studio. Flutter Web đóng gói key vào JavaScript trình
duyệt, nên cấu hình này chỉ dành cho demo cục bộ; bản phát hành thật cần gọi AI
qua backend để giữ key ở máy chủ.
Nếu không truyền key, app vẫn chạy đầy đủ các chức năng khác; các tính năng AI
sẽ chatbot tư vấn bằng dữ liệu có sẵn ở chế độ offline; các tác vụ AI tạo sinh
sẽ hiện thông báo **“Tính năng AI chưa khả dụng”**.

## Dữ liệu và tài khoản trong bản demo

Ứng dụng không kết nối Firebase. Danh mục, đơn đặt và yêu thích mẫu được lưu
cục bộ trên thiết bị bằng SharedPreferences; chúng không đồng bộ giữa thiết bị.
Tài khoản đăng ký, mật khẩu đã băm và phiên đăng nhập cũng được lưu cục bộ,
nên vẫn còn sau khi tải lại trang trên cùng thiết bị/trình duyệt. Đây là xác thực
demo, không thay thế dịch vụ xác thực an toàn cho sản phẩm thật. Có thể chuyển
giữa vai trò Khách và Quản trị viên demo từ trang Hồ sơ để thử các luồng.

Nếu cổng 8080 đang được ứng dụng khác sử dụng, đổi `--web-port 8081` và mở
http://localhost:8081. Cấu hình Codespaces vẫn dùng cổng 8080.

## Kiểm tra trước khi push

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
git status
```

Không commit `node_modules/`, `.dart_tool/`, `build/` hoặc thông tin đăng nhập.
Các thư mục sinh tự động đã được loại trừ trong `.gitignore`.

## Collaborator và nộp bài

Đã kiểm tra ngày 24/09/2026: `huanonana` là chủ repo; `lehiu1310` và
`Longsokiuu` đều có quyền ghi (write). Chưa thấy tài khoản giảng viên trong
danh sách collaborator đã chấp nhận; chưa kiểm tra được lời mời đang chờ.

Chủ repo vào **Settings → Collaborators → Add people** để kiểm tra/mời
`lethunguyen` **hoặc** `nglthu` (chọn đúng tài khoản theo hướng dẫn của lớp).
Tài khoản `lehiu1310` không có quyền quản trị để thực hiện bước này.

Nội dung phản hồi/nộp bài:

> Đề tài: Xây dựng ứng dụng quản lý homestay — Huấn, Hiếu, Long.
>
> Phạm Văn Huấn — 23010331; Nguyễn Hữu Lê Hiếu — 23010985;
> Nguyễn Hải Long — 2301872.
>
> Repo: https://github.com/huanonana/nhom_huan_hieu_long

Chụp minh chứng từ phiên chạy thật: VS Code/Codespaces với thư mục
`.devcontainer`, terminal chạy Flutter và trình duyệt hiển thị tên nhóm,
MSSV trong hộp thoại thông tin nhóm. Ảnh mẫu của nhóm khác chỉ để tham khảo.
Kiểm tra trạng thái nộp bài trên hệ thống lớp riêng; không suy ra đã nộp
từ việc có mã nguồn trên GitHub.

## Tài liệu

- Báo cáo đồ án Word/PDF: `output/report/Bao_cao_do_an_HHL_Stay.docx` and `.pdf`.
  The report source and captured app screens are in `tool/generate_hhl_report.py`
  and `docs/report_assets/`; regenerate with `python tool/generate_hhl_report.py`
  after installing `python-docx` and Pillow.
- [Flutter Web](https://docs.flutter.dev/platform-integration/web/setup)
- [Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container CLI](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli)

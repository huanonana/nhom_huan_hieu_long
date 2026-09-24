# Xây dựng ứng dụng quản lý homestay — Huấn, Hiếu, Long

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

- [Flutter Web](https://docs.flutter.dev/platform-integration/web/setup)
- [Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container CLI](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli)

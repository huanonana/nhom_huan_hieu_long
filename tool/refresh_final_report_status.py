"""Align report statements with the current local and Firebase builds."""
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Inches, Pt, RGBColor

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "output" / "report" / "Bao_cao_do_an_HHL_Stay.docx"
PHONE_SCREENSHOT = ROOT / "tmp" / "medium_phone_explore_verified.png"

replacements = {
    "Phạm vi gồm Flutter Web, 14 homestay mẫu, tìm kiếm/lọc, chi tiết, booking, yêu thích, quản lý đơn, lịch, bảo trì, thống kê local, đánh giá và một số tác vụ AI tùy cấu hình. Ngoài phạm vi là xác thực thật, backend, thanh toán, thông báo push, bản đồ và kiểm chứng chỗ nghỉ.":
    "Phạm vi gồm Flutter Web và Android, 14 homestay mẫu, tìm kiếm/lọc, chi tiết, booking, yêu thích, quản lý đơn, lịch, bảo trì, thống kê, đánh giá và AI tùy cấu hình. Local mode lưu dữ liệu trên thiết bị; Firebase mode tùy chọn cung cấp Firebase Authentication và Firestore cho các luồng đã tích hợp. Ngoài phạm vi là thanh toán thật, thông báo push, bản đồ, xác minh chỗ nghỉ và đồng bộ production hoàn chỉnh.",
    "SharedPreferences là kho key-value cục bộ, phù hợp dữ liệu demo. Repo dùng để giữ danh mục, booking, yêu thích và phiên demo trong cùng trình duyệt. Dữ liệu không đồng bộ đa thiết bị, không có transaction phân tán và có thể mất khi xóa storage.":
    "Trong local mode, SharedPreferences là kho key-value cục bộ cho danh mục, booking, yêu thích và phiên demo trên cùng thiết bị/trình duyệt. Dữ liệu local không tự đồng bộ đa thiết bị, không có transaction phân tán và có thể mất khi xóa storage. Firebase mode tùy chọn bổ sung lưu hồ sơ, booking và các document domain đã hỗ trợ.",
    "Kiến trúc tách model, repository, state và presentation. UI nhận dữ liệu qua provider; repository truy cập local storage. Muốn chuyển sang server cần API, xác thực, quyền, xử lý đồng thời, migration và integration tests.":
    "Kiến trúc tách model, repository, state và presentation. UI nhận dữ liệu qua provider; local mode dùng SharedPreferences, còn Firebase mode dùng FirebaseAuthRepository và FirebaseDocumentStore. Trước khi vận hành production vẫn cần phân quyền chặt, xử lý đồng thời, migration và integration tests.",
    "Bản demo không kết nối Firebase hay server auth. Tài khoản/booking ở browser này không tự xuất hiện ở máy khác. Production cần xác minh danh tính ở server, kiểm soát quyền từng bản ghi, TLS, quản lý secret và audit.":
    "Local mode không kết nối Firebase; tài khoản và dữ liệu local không tự xuất hiện ở thiết bị khác. Firebase mode tùy chọn kết nối Firebase Authentication và Firestore cho các luồng đã tích hợp. Rules hiện là rules phát triển rộng, vì vậy không dùng cho dữ liệu thật; production cần phân quyền theo UID/role/chủ sở hữu, xác minh server và audit.",
    "Màn bookings đọc các đơn trong cùng browser storage, hiển thị trạng thái và hủy khi được phép. Browser quản trị khác không thấy đơn do không có đồng bộ máy chủ.":
    "Trong local mode, màn bookings đọc đơn từ storage cùng thiết bị và không đồng bộ sang browser khác. Firebase mode tùy chọn đọc/ghi booking Firestore khi đã bật cấu hình, nhưng chưa có queue retry hay cơ chế giải quyết xung đột đa thiết bị đầy đủ.",
    "Dashboard có chỉ số vận hành và biểu đồ booking demo. Số liệu chỉ là trạng thái local, không đại diện doanh thu thực hoặc nhiều cơ sở.":
    "Dashboard tổng hợp booking và chi phí demo. Ở local mode số liệu lấy từ storage trên thiết bị; ở Firebase mode app tải các document tài chính đã hỗ trợ. Số liệu không đại diện doanh thu thực, đối soát thanh toán hay báo cáo đa cơ sở production.",
    "Không có user thật, backend, cổng thanh toán hoặc đa thiết bị. Browser smoke test chỉ một môi trường. Test pass không chứng minh đã chạy mọi tác vụ với tài khoản thực.":
    "Chưa có người dùng production, thanh toán thật hoặc kiểm thử end-to-end với Firebase backend/emulator. Browser smoke test và Medium Phone emulator chỉ là môi trường demo; test pass không chứng minh vận hành production hay giao dịch đồng thời nhiều thiết bị.",
    "Nhóm đã xây dựng prototype cho khám phá, chi tiết, booking demo và quản trị local. Lần kiểm tra 24/10/2026, flutter analyze không phát hiện vấn đề và 96 test tự động đều qua. Kết quả chứng minh các ca đã kiểm thử trong phạm vi local, không chứng nhận backend hoặc vận hành production.":
    "Nhóm đã xây dựng app Flutter cho khám phá, chi tiết, booking demo và quản trị. Local mode dùng dữ liệu thiết bị; Firebase mode tùy chọn tích hợp Firebase Authentication/Firestore. Lần kiểm tra 24/10/2026, flutter analyze không phát hiện vấn đề, 96 test tự động đều qua, Web local và Android debug APK build thành công; Medium Phone emulator chạy được luồng landing → Explore → chi tiết → yêu cầu đặt phòng và chuyển sang đăng nhập. Firebase live auth/Firestore và vận hành production chưa được chứng nhận.",
    "Cấu trúc provider/repository hỗ trợ kiểm thử và thay đổi data source. Prototype đáp ứng trình diễn các luồng khách và host, đồng thời báo cáo phân biệt dữ liệu demo với tính năng chưa có ở môi trường thật. Trước triển khai thực tế cần backend, xác thực/phân quyền máy chủ, giao dịch đặt phòng đồng thời, thanh toán và xác minh ảnh.":
    "Cấu trúc provider/repository hỗ trợ kiểm thử và thay đổi data source. App đáp ứng trình diễn luồng khách và host ở local mode, đồng thời có Firebase mode tùy chọn cho các luồng đã tích hợp. Trước triển khai thực tế vẫn cần rules phân quyền chặt, giao dịch booking phía server, thanh toán và xác minh ảnh.",
    "Firebase-enabled Android debug compile/package; not installed on a device":
    "Firebase-enabled Android debug compile/package; launcher smoke passed, live Firebase not tested",
    "Ảnh trợ lý ghi trạng thái offline/chưa khả dụng. Nguyên nhân có thể là key, quota, model hoặc mạng; chưa gọi online có key trong lần kiểm tra. Không lưu API key trong báo cáo.":
    "Trong lần kiểm tra hiện tại, Gemini online chưa được gọi vì bản build không có API key; chat vẫn có local fallback và trả gợi ý theo danh mục. Trạng thái key, quota, model và mạng quyết định khả năng online. Không lưu API key trong báo cáo.",
}

doc = Document(REPORT)
replaced = set()
present = {p.text for p in doc.paragraphs}
for paragraph in doc.paragraphs:
    if paragraph.text in replacements:
        replaced.add(paragraph.text)
        paragraph.text = replacements[paragraph.text]
for table in doc.tables:
    for row in table.rows:
        for cell in row.cells:
            for paragraph in cell.paragraphs:
                if paragraph.text in replacements:
                    replaced.add(paragraph.text)
                    paragraph.text = replacements[paragraph.text]
present.update(
    p.text
    for table in doc.tables
    for row in table.rows
    for cell in row.cells
    for p in cell.paragraphs
)
missing = {
    old for old, new in replacements.items() if old not in replaced and new not in present
}
if missing:
    raise RuntimeError("Expected report passages not found: " + " | ".join(sorted(missing)))

if any(p.text == "PHỤ LỤC I. KIỂM TRA MEDIUM PHONE" for p in doc.paragraphs):
    doc.save(REPORT)
    print("The local/Medium Phone evidence appendix already exists; report updates are current.")
    raise SystemExit(0)

if not any(p.text == "PHỤ LỤC I. KIỂM TRA MEDIUM PHONE" for p in doc.paragraphs):
    doc.add_page_break()
title = doc.add_paragraph()
title.style = "Title"
title.alignment = WD_ALIGN_PARAGRAPH.LEFT
run = title.add_run("PHỤ LỤC I. KIỂM TRA MEDIUM PHONE")
run.font.name = "Arial"
run.font.size = Pt(20)
run.font.bold = True
run.font.color.rgb = RGBColor(48, 54, 125)
subtitle = doc.add_paragraph("Kết quả xác nhận ngày 24/10/2026")
subtitle.style = "Subtitle"
for run in subtitle.runs:
    run.font.name = "Arial"
    run.font.size = Pt(10)
    run.font.color.rgb = RGBColor(90, 105, 130)

paragraph = doc.add_paragraph(
    "Bản local được build lại từ workspace và phục vụ tại http://127.0.0.1:8083. "
    "APK local được cài lên Android Medium Phone emulator 1080 × 2400. Thao tác "
    "landing → Explore → chi tiết homestay → chọn ngày/đặt phòng đưa khách chưa "
    "đăng nhập tới màn đăng nhập; logcat không ghi nhận Flutter exception hoặc crash."
)
paragraph.paragraph_format.space_after = Pt(6)
paragraph.paragraph_format.line_spacing = 1.05
for run in paragraph.runs:
    run.font.name = "Arial"
    run.font.size = Pt(9.5)

table = doc.add_table(rows=1, cols=3)
table.style = "Table Grid"
headers = ["Kiểm tra", "Kết quả", "Giới hạn"]
for i, value in enumerate(headers):
    cell = table.rows[0].cells[i]
    cell.text = value
    for run in cell.paragraphs[0].runs:
        run.bold = True
        run.font.name = "Arial"
        run.font.size = Pt(8.5)
for row in [
    ("flutter analyze", "No issues found", "Static analysis"),
    ("flutter test", "96/96 passed", "Unit/widget tests"),
    ("flutter build web", "Built build/web", "Local mode"),
    ("flutter build apk --debug", "Built and installed", "Local mode on emulator"),
    ("localhost 8083 / setup 8099", "HTTP 200 / HTTP 200", "Browser smoke"),
    ("Android route smoke", "Landing → Explore → detail → login", "No crash/Flutter exception"),
]:
    cells = table.add_row().cells
    for i, value in enumerate(row):
        cells[i].text = value
        for run in cells[i].paragraphs[0].runs:
            run.font.name = "Arial"
            run.font.size = Pt(8.2)
for row in table.rows:
    for i, width in enumerate((1.65, 2.2, 2.3)):
        row.cells[i].width = Inches(width)

if not PHONE_SCREENSHOT.exists():
    raise FileNotFoundError(PHONE_SCREENSHOT)
image_paragraph = doc.add_paragraph()
image_paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
image_paragraph.paragraph_format.space_before = Pt(4)
image_paragraph.paragraph_format.space_after = Pt(2)
image_paragraph.add_run().add_picture(str(PHONE_SCREENSHOT), width=Inches(1.9))
caption = doc.add_paragraph("Hình I.1. Giao diện Explore đang chạy trên Medium Phone emulator.")
caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
for run in caption.runs:
    run.font.name = "Arial"
    run.font.size = Pt(8)
    run.italic = True

doc.save(REPORT)
print(f"Updated {REPORT}; refreshed {len(replaced)} report statements and added local/Android evidence.")

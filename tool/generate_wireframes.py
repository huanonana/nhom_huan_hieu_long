"""Render six HHL Stay mobile wireframes for the Phenikaa report."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "wireframes"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 760, 1500
INK = "#18213A"
MUTED = "#64748B"
LINE = "#D8E0ED"
BG = "#F5F7FC"
WHITE = "#FFFFFF"
PURPLE = "#5148E5"
PALE = "#EEF0FF"
GREEN = "#DDF7EC"

font_path = Path("C:/Windows/Fonts/segoeui.ttf")
bold_path = Path("C:/Windows/Fonts/segoeuib.ttf")


def font(size: int, bold: bool = False):
    path = bold_path if bold else font_path
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def canvas(title: str, subtitle: str):
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    d.text((34, 22), "9:41   ●  Wi-Fi  ▰", fill=MUTED, font=font(22))
    d.text((36, 68), title, fill=INK, font=font(33, True))
    d.text((36, 112), subtitle, fill=MUTED, font=font(21))
    d.line((28, 156, W - 28, 156), fill=LINE, width=2)
    return im, d


def box(d, xy, fill=WHITE, outline=LINE, radius=22, width=2):
    d.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def label(d, x, y, text, size=22, color=INK, bold=False):
    d.text((x, y), text, fill=color, font=font(size, bold))


def button(d, xy, text, primary=False):
    box(d, xy, fill=PURPLE if primary else WHITE,
        outline=PURPLE if primary else LINE, radius=20)
    f = font(23, True)
    bb = d.textbbox((0, 0), text, font=f)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    x1, y1, x2, y2 = xy
    d.text(((x1 + x2 - tw) / 2, (y1 + y2 - th) / 2 - 3), text,
           fill=WHITE if primary else PURPLE, font=f)


def bottom_nav(d, selected="Khám phá"):
    y = 1380
    d.rectangle((0, y, W, H), fill=WHITE)
    d.line((0, y, W, y), fill=LINE, width=2)
    items = ["Trang chủ", "Khám phá", "Yêu thích", "Đơn đặt", "Tài khoản"]
    for i, item in enumerate(items):
        cx = 76 + i * 152
        c = PURPLE if item == selected else MUTED
        d.ellipse((cx - 13, y + 22, cx + 13, y + 48), outline=c, width=3)
        f = font(16, item == selected)
        bb = d.textbbox((0, 0), item, font=f)
        d.text((cx - (bb[2] - bb[0]) / 2, y + 57), item, fill=c, font=f)


def image_placeholder(d, xy, caption="Ảnh homestay"):
    box(d, xy, fill="#E7EBF4", outline="#D4DCEB", radius=18)
    x1, y1, x2, y2 = xy
    cx = (x1 + x2) // 2
    d.rectangle((cx - 38, y1 + (y2-y1)//2 - 24,
                 cx + 38, y1 + (y2-y1)//2 + 24), outline="#A8B4C8", width=3)
    d.ellipse((cx + 12, y1 + (y2-y1)//2 - 14,
               cx + 23, y1 + (y2-y1)//2 - 3), fill="#A8B4C8")
    label(d, x1 + 12, y2 - 40, caption, 17, MUTED)


def field(d, y, title, value, x1=38, x2=722, h=82):
    label(d, x1 + 4, y, title, 18, MUTED)
    box(d, (x1, y + 28, x2, y + 28 + h), fill=WHITE)
    label(d, x1 + 20, y + 52, value, 21, INK)


def make_home():
    im, d = canvas("HHL Stay", "Trang chủ · điểm bắt đầu hành trình")
    box(d, (34, 178, 726, 248), fill=WHITE)
    label(d, 58, 196, "⌂  HHL Stay", 25, PURPLE, True)
    label(d, 579, 199, "Đăng nhập", 18, PURPLE, True)
    box(d, (34, 274, 726, 795), fill=WHITE, radius=30)
    label(d, 68, 308, "HHL STAY  ·  HOMESTAY VIỆT NAM", 16, PURPLE, True)
    label(d, 68, 354, "Ở như người bản địa,", 35, INK, True)
    label(d, 68, 400, "nghỉ như ở nhà.", 35, PURPLE, True)
    label(d, 68, 459, "Khám phá chỗ nghỉ có cá tính, giá rõ ràng", 18, MUTED)
    label(d, 68, 488, "và đặt phòng an tâm cho chuyến đi.", 18, MUTED)
    button(d, (68, 535, 370, 608), "Khám phá homestay", True)
    image_placeholder(d, (68, 632, 692, 765), "Ảnh trải nghiệm / homestay nổi bật")
    label(d, 42, 830, "Tìm chỗ nghỉ phù hợp", 28, INK, True)
    box(d, (34, 882, 726, 978), fill=WHITE)
    label(d, 62, 914, "⌕  Thành phố, homestay hoặc khu vực", 20, MUTED)
    label(d, 42, 1014, "Điểm đến nổi bật", 27, INK, True)
    for i, city in enumerate(["Đà Lạt", "Đà Nẵng", "Cần Thơ"]):
        x = 34 + i * 231
        image_placeholder(d, (x, 1068, x + 214, 1298), city)
        label(d, x + 6, 1310, city, 19, INK, True)
    bottom_nav(d, "Trang chủ")
    im.save(OUT / "01-home.png")


def make_explore():
    im, d = canvas("Khám phá", "Tìm nơi nghỉ theo điểm đến và nhu cầu")
    box(d, (34, 178, 726, 258), fill=WHITE)
    label(d, 60, 205, "⌕  Tìm homestay, khu vực...", 21, MUTED)
    label(d, 40, 286, "Lọc nhanh", 23, INK, True)
    chips = [("Tất cả", 34, 350, 154), ("Có bếp", 174, 350, 300),
             ("Có hồ bơi", 320, 350, 485), ("Giá", 502, 350, 646)]
    for text, x1, y, x2 in chips:
        box(d, (x1, y, x2, y + 58), fill=PALE if text == "Tất cả" else WHITE,
            outline=PURPLE if text == "Tất cả" else LINE, radius=24)
        label(d, x1 + 18, y + 16, text, 17, PURPLE if text == "Tất cả" else INK)
    label(d, 40, 444, "Chỗ nghỉ phù hợp", 28, INK, True)
    label(d, 42, 488, "12 kết quả · sắp xếp theo đề xuất", 18, MUTED)
    for index, (city, name, price) in enumerate([
        ("Đà Lạt", "Nhà Gỗ Bên Đồi", "850.000đ / đêm"),
        ("Đà Nẵng", "An Nhiên House", "1.100.000đ / đêm"),
        ("Cần Thơ", "Mekong Garden Stay", "720.000đ / đêm"),
    ]):
        y = 542 + index * 256
        box(d, (34, y, 726, y + 222), fill=WHITE)
        image_placeholder(d, (50, y + 16, 292, y + 205), city)
        label(d, 316, y + 23, city.upper(), 15, PURPLE, True)
        label(d, 316, y + 55, name, 23, INK, True)
        label(d, 316, y + 98, "★  4.8  ·  2 phòng", 18, MUTED)
        label(d, 316, y + 146, price, 18, INK, True)
        label(d, 316, y + 179, "Xem chi tiết  →", 17, PURPLE, True)
    bottom_nav(d, "Khám phá")
    im.save(OUT / "02-explore.png")


def make_detail():
    im, d = canvas("Chi tiết homestay", "Ảnh · tiện nghi · phòng · đánh giá")
    image_placeholder(d, (34, 180, 726, 510), "Gallery: ảnh phòng / khu vực / tiện ích")
    label(d, 42, 540, "ĐÀ LẠT  ·  LÂM ĐỒNG", 16, PURPLE, True)
    label(d, 42, 580, "Nhà Gỗ Bên Đồi", 32, INK, True)
    label(d, 42, 632, "★ 4.8  ·  36 đánh giá  ·  Xem bản đồ", 18, MUTED)
    label(d, 42, 694, "Không gian nghỉ riêng tư giữa thiên nhiên,", 19, INK)
    label(d, 42, 724, "đầy đủ tiện nghi cho chuyến đi thư thái.", 19, INK)
    label(d, 42, 787, "Tiện nghi nổi bật", 25, INK, True)
    for i, item in enumerate(["Wi-Fi", "Bếp", "Ban công", "Đỗ xe"]):
        x = 34 + (i % 2) * 348
        y = 840 + (i // 2) * 66
        box(d, (x, y, x + 330, y + 52), fill=WHITE, radius=18)
        label(d, x + 18, y + 13, "✓  " + item, 18, INK)
    label(d, 42, 1000, "Chọn phòng", 25, INK, True)
    box(d, (34, 1050, 726, 1240), fill=WHITE)
    label(d, 58, 1074, "Phòng Deluxe", 22, INK, True)
    label(d, 58, 1110, "2 khách  ·  1 giường  ·  Miễn phí hủy", 17, MUTED)
    label(d, 58, 1165, "850.000đ / đêm", 21, PURPLE, True)
    button(d, (34, 1280, 726, 1360), "Chọn ngày & đặt phòng", True)
    bottom_nav(d, "Khám phá")
    im.save(OUT / "03-detail.png")


def make_booking():
    im, d = canvas("Đặt phòng", "Xác nhận ngày ở và thông tin khách")
    label(d, 42, 186, "1  Phòng   —   2  Ngày   —   3  Xác nhận", 18, PURPLE, True)
    box(d, (34, 238, 726, 378), fill=WHITE)
    image_placeholder(d, (48, 252, 196, 364), "")
    label(d, 214, 258, "Nhà Gỗ Bên Đồi", 22, INK, True)
    label(d, 214, 297, "Phòng Deluxe · Đà Lạt", 17, MUTED)
    label(d, 214, 335, "850.000đ / đêm", 19, PURPLE, True)
    field(d, 410, "Tên khách", "Tên hiển thị từ tài khoản")
    field(d, 532, "Ngày nhận — ngày trả", "Chọn ngày  →")
    field(d, 654, "Số khách", "2 khách  ▾")
    field(d, 776, "Mã ưu đãi", "Nhập mã (ví dụ HHL10)")
    label(d, 42, 918, "Chi tiết giá", 25, INK, True)
    for i, (left, right) in enumerate([
        ("2 đêm × 850.000đ", "1.700.000đ"),
        ("Ưu đãi thành viên", "−85.000đ"),
        ("Mã giảm giá", "−161.500đ"),
    ]):
        y = 970 + i * 56
        label(d, 48, y, left, 18, MUTED)
        label(d, 548, y, right, 18, INK)
    d.line((42, 1150, 718, 1150), fill=LINE, width=2)
    label(d, 48, 1170, "Tổng thanh toán tại homestay", 17, MUTED)
    label(d, 48, 1203, "1.453.500đ", 27, INK, True)
    button(d, (34, 1280, 726, 1360), "Gửi yêu cầu đặt phòng", True)
    bottom_nav(d, "Đơn đặt")
    im.save(OUT / "04-booking.png")


def make_login():
    im, d = canvas("Đăng nhập", "Tài khoản khách hàng")
    box(d, (34, 194, 726, 1308), fill=WHITE, radius=30)
    label(d, 70, 238, "HHL Stay", 28, PURPLE, True)
    label(d, 70, 318, "Chào mừng bạn trở lại", 33, INK, True)
    label(d, 70, 370, "Đăng nhập để tiếp tục hành trình.", 18, MUTED)
    box(d, (66, 435, 694, 510), fill=PALE, outline="#C9CCFF")
    label(d, 90, 458, "Hướng dẫn thao tác  ▾", 19, PURPLE, True)
    field(d, 558, "Email", "ten@example.com", x1=68, x2=692, h=76)
    field(d, 685, "Mật khẩu", "••••••••", x1=68, x2=692, h=76)
    label(d, 76, 831, "Quên mật khẩu?", 17, PURPLE)
    button(d, (68, 900, 692, 978), "Đăng nhập", True)
    label(d, 135, 1012, "Chưa có tài khoản?  Đăng ký", 19, PURPLE, True)
    d.line((84, 1084, 676, 1084), fill=LINE, width=2)
    label(d, 163, 1110, "Đăng nhập Chủ nhà / Admin", 18, INK)
    label(d, 154, 1190, "Google / Apple (sắp phát triển)", 17, MUTED)
    bottom_nav(d, "Tài khoản")
    im.save(OUT / "05-login.png")


def make_admin():
    im, d = canvas("Quản trị HHL Stay", "Dashboard chủ nhà / admin")
    box(d, (34, 178, 726, 247), fill=WHITE)
    label(d, 56, 200, "☰  HHL Stay", 22, PURPLE, True)
    label(d, 545, 203, "24/10/2026  ●", 17, MUTED)
    label(d, 42, 282, "Tổng quan vận hành", 29, INK, True)
    for i, (name, value, color) in enumerate([
        ("Đơn cần xử lý", "8", PALE),
        ("Doanh thu demo", "12.4tr", GREEN),
        ("Phòng đang ở", "11", "#FFF4DB"),
        ("Bảo trì", "2", "#FDE8E8"),
    ]):
        x = 34 + (i % 2) * 350
        y = 344 + (i // 2) * 152
        box(d, (x, y, x + 332, y + 128), fill=WHITE)
        d.ellipse((x + 18, y + 22, x + 66, y + 70), fill=color)
        label(d, x + 82, y + 22, name, 16, MUTED)
        label(d, x + 82, y + 52, value, 27, INK, True)
    label(d, 42, 675, "Doanh thu theo tháng", 24, INK, True)
    box(d, (34, 728, 726, 954), fill=WHITE)
    # Simple editable chart guides.
    for i, height in enumerate([88, 125, 103, 164, 138, 184]):
        x = 83 + i * 95
        d.rounded_rectangle((x, 920 - height, x + 46, 920), radius=10,
                            fill="#A8A4F8" if i < 5 else PURPLE)
    for y in (776, 824, 872, 920):
        d.line((64, y, 696, y), fill="#E8ECF4", width=1)
    label(d, 42, 995, "Thao tác nhanh", 24, INK, True)
    for i, text in enumerate(["Đơn đặt", "Lịch phòng", "Thu / chi", "Nhân sự"]):
        x = 34 + (i % 2) * 350
        y = 1045 + (i // 2) * 92
        button(d, (x, y, x + 330, y + 70), text)
    bottom_nav(d, "Tài khoản")
    im.save(OUT / "06-admin-dashboard.png")


if __name__ == "__main__":
    for build in (make_home, make_explore, make_detail, make_booking,
                  make_login, make_admin):
        build()
    print(f"Generated six wireframes in {OUT}")

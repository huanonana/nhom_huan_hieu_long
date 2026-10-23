from docx import Document
from docx.shared import Cm,Pt,RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_TAB_ALIGNMENT, WD_TAB_LEADER
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from PIL import Image
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'output/report'; AS=ROOT/'docs/report_assets'; OUT.mkdir(parents=True,exist_ok=True)
# Build substantial page-by-page report sections. Each section starts on a new page.
P=[]
def a(title,text,bullets='',img=''):
 P.append((title,text,bullets.split('|') if bullets else [],img))
a('Lời cam đoan','Báo cáo mô tả đề tài HHL Stay dựa trên mã nguồn, tài liệu repository và trạng thái ứng dụng quan sát ngày 23/10/2026. Homestay, giá, tài khoản và booking mẫu là dữ liệu minh họa. Các giới hạn chưa kiểm chứng được ghi rõ, không khẳng định quá khả năng của bản thử.')
a('Lời cảm ơn','Nhóm xin cảm ơn giảng viên đã hướng dẫn quy trình đồ án gồm phân tích yêu cầu, mô hình hóa, thiết kế giao diện và kiểm thử. Góp ý về User Stories, Class Diagram, Sequence/Activity Diagrams và mockup là căn cứ rà soát sản phẩm.')
a('Tóm tắt','HHL Stay là ứng dụng web thử nghiệm hỗ trợ khám phá homestay, xem phòng, gửi booking và thao tác quản trị cơ bản. Ứng dụng dùng Flutter/Dart, Riverpod, go_router và SharedPreferences. Báo cáo trình bày yêu cầu, mô hình, giao diện, triển khai và kiểm thử. Phạm vi hiện tại là prototype cục bộ, chưa có backend, xác thực máy chủ, thanh toán hoặc đồng bộ đa thiết bị.')
a('Abstract','HHL Stay is a Flutter Web prototype for discovering homestays, reviewing rooms, submitting booking requests, and trying basic host operations. It uses Riverpod, go_router, and device-local SharedPreferences storage. This report covers user stories, requirements, UML, implementation, and tests. The current build is an academic demo and does not provide production authentication, shared backend, or payment processing.')
a('Mục lục và quy ước','Báo cáo gồm sáu chương và bảy phụ lục. Số trang được đối chiếu bản Word xuất PDF cuối, tính theo trang in. Các ảnh ghi lại giao diện app local; sơ đồ mô tả luồng hiện có và chỉ rõ giới hạn prototype.','Chương 1: Mở đầu ........................................ 7|Chương 2: Cơ sở lý thuyết ........................... 11|Chương 3: Phân tích và thiết kế .................... 16|Chương 4: Triển khai .................................... 25|Chương 5: Kiểm thử và đánh giá ................. 32|Chương 6: Kết luận ....................................... 38|Tài liệu tham khảo ....................................... 41|Phụ lục A: Hướng dẫn chạy ........................ 42|Phụ lục B: Kết quả kiểm thử ........................ 43|Phụ lục C: Đối chiếu yêu cầu ....................... 44|Phụ lục D: Thuật ngữ ..................................... 45|Phụ lục E: Sơ đồ UML bổ sung .................... 45–47|Phụ lục F: Bảng phân tích chi tiết ............... 48–56|Phụ lục G: Ảnh chụp giao diện .................. 57–63')
a('Danh mục hình và bảng','Các hình UML được xây dựng theo nghiệp vụ và đối chiếu với model/repository hiện có. Báo cáo có một Class Diagram, một Use Case Diagram, ba Activity Diagram, bốn Sequence Diagram và một sơ đồ vòng đời booking. Bảng chi tiết ở Phụ lục F.','Hình 3.1 Sơ đồ lớp dữ liệu HHL Stay ............ 21|Hình 3.2 Use Case theo tác nhân .................... 21|Hình 3.3 Activity gửi yêu cầu đặt phòng .......... 22|Hình 3.4 Sequence tạo booking ..................... 22|Hình 3.5 Vòng đời booking ............................ 23|Hình 3.6 Activity tìm kiếm và lọc ..................... 45|Hình 3.7 Activity nhận và trả phòng ............... 45|Hình 3.8 Sequence duyệt booking ................. 46|Hình 3.9 Sequence gửi đánh giá .................... 46|Hình 3.10 Sequence tổng hợp tài chính .......... 47|Hình C.1 Flow of Work của nhóm .................... 44|Bảng F.1 User Stories và tiêu chí chấp nhận ... 48|Bảng F.2 Ma trận yêu cầu chức năng ............. 49|Bảng F.3 Tác nhân, quyền và quan hệ ............ 50|Bảng F.4 Từ điển dữ liệu ............................... 51|Bảng F.5 Trạng thái booking và ngày ở .......... 52|Bảng F.6 Công thức tài chính ........................ 53|Bảng F.7 Ma trận kiểm thử hồi quy ................. 54|Bảng F.8 Quy trình thao tác demo ................. 55|Bảng F.9 Giới hạn và rủi ro ............................ 56')
a('CHƯƠNG 1. MỞ ĐẦU','Chương này nêu bối cảnh, vấn đề, mục tiêu và phạm vi. HHL Stay mô phỏng chuỗi từ tìm nơi nghỉ đến quản lý yêu cầu đặt phòng, với giao diện riêng cho khách và người vận hành.')
a('1.1 Bối cảnh đề tài','Khách phải đối chiếu điểm đến, giá, số khách, vị trí và ngày còn phòng. Cơ sở lưu trú nhỏ cần theo dõi đơn, lịch phòng và bảo trì. Bảng tính rời dễ gây bỏ sót hoặc đặt trùng. Đề tài tạo prototype để minh họa các nhu cầu đó trong môi trường học tập.')
a('1.2 Phát biểu vấn đề','Hệ thống cần giúp khách tra cứu thông tin nhất quán và người vận hành theo dõi booking. Nếu ngày, sức chứa, giá và trạng thái không được kiểm tra đồng bộ, kết quả đặt có thể sai. Bản thử cần biểu diễn luồng chính, lưu lại sau refresh cùng trình duyệt và làm rõ giới hạn khi chưa có máy chủ.')
a('1.3 Mục tiêu','Phát triển ứng dụng web Flutter; tổ chức giao diện, trạng thái và repository; tạo danh mục mẫu; hỗ trợ tìm kiếm, yêu thích, gửi và xử lý đơn demo; trình bày màn vận hành.','Minh họa luồng khách.|Minh họa quản lý phòng, lịch và số liệu demo.|Kiểm tra validation và lưu cục bộ bằng test.')
a('1.4 Đối tượng sử dụng','Khách tìm chỗ nghỉ, xem phòng, đặt và theo dõi kết quả. Host/Admin quản lý danh mục, xử lý đơn, cập nhật phòng và xem số liệu. Trong demo, chuyển vai trò chỉ phục vụ thử giao diện, không phải phân quyền an toàn.')
a('1.5 Phạm vi','Phạm vi gồm Flutter Web, 14 homestay mẫu, tìm kiếm/lọc, chi tiết, booking, yêu thích, quản lý đơn, lịch, bảo trì, thống kê local, đánh giá và một số tác vụ AI tùy cấu hình. Ngoài phạm vi là xác thực thật, backend, thanh toán, thông báo push, bản đồ và kiểm chứng chỗ nghỉ.')
a('1.6 Phương pháp','Nhóm khảo sát nghiệp vụ, xác định tác nhân/quy tắc, phác thảo mô hình, triển khai từng luồng rồi kiểm tra analyzer, unit/widget tests và browser. Quy ước ngày ở [check-in, check-out), sức chứa phải phù hợp, lịch trùng bị từ chối và đơn chờ có thời hạn demo.')
a('1.7 Tổ chức báo cáo','Chương 2 giới thiệu công nghệ; chương 3 mô tả tác nhân, Stories, dữ liệu và UML; chương 4 trình bày triển khai; chương 5 nêu kiểm thử; chương 6 tổng kết và đề xuất.')
a('CHƯƠNG 2. CƠ SỞ LÝ THUYẾT','Phần này tóm tắt nền tảng kỹ thuật hiện diện trong mã nguồn và lý do lựa chọn.')
a('2.1 Flutter và Dart','Flutter mô tả UI bằng widget; Dart triển khai model, repository và logic. Flutter Web phục vụ app trong trình duyệt. Widget tree hỗ trợ tách thành phần kiểm thử, nhưng cần quản lý rebuild, vòng đời và bố cục co giãn.')
a('2.2 Riverpod','Riverpod cung cấp provider để nối UI với trạng thái và dịch vụ. Widget theo dõi provider và cập nhật khi dữ liệu thay đổi. Tách nghiệp vụ khỏi widget giúp kiểm thử và thay data source dễ hơn.')
a('2.3 go_router','go_router ánh xạ URL vào màn hình, hỗ trợ điều hướng web và route lồng nhau. Các route gồm khám phá, chi tiết, đặt phòng và host. Guard phía client chỉ là điều hướng, không thay thế kiểm tra quyền server.')
a('2.4 SharedPreferences','SharedPreferences là kho key-value cục bộ, phù hợp dữ liệu demo. Repo dùng để giữ danh mục, booking, yêu thích và phiên demo trong cùng trình duyệt. Dữ liệu không đồng bộ đa thiết bị, không có transaction phân tán và có thể mất khi xóa storage.')
a('2.5 Kiến trúc','Kiến trúc tách model, repository, state và presentation. UI nhận dữ liệu qua provider; repository truy cập local storage. Muốn chuyển sang server cần API, xác thực, quyền, xử lý đồng thời, migration và integration tests.')
a('2.6 Lưu trữ và bảo mật','Bản demo không kết nối Firebase hay server auth. Tài khoản/booking ở browser này không tự xuất hiện ở máy khác. Production cần xác minh danh tính ở server, kiểm soát quyền từng bản ghi, TLS, quản lý secret và audit.')
a('2.7 Nghiệp vụ booking','Booking gồm khách, phòng, ngày nhận/trả, số khách, snapshot giá, tổng tiền và trạng thái. Tổng tiền cơ bản bằng giá mỗi đêm nhân số đêm. Khoảng [nhận,trả) cho phép khách sau nhận đúng ngày khách trước trả; snapshot giúp giữ giá lịch sử.')
a('2.8 Đối chiếu thị trường','Dịch vụ đặt phòng thường hỗ trợ tìm theo nơi/ngày/số khách, so sánh phòng, xem giá/điều kiện, xác nhận và theo dõi. HHL Stay mô phỏng chuỗi tác vụ phổ biến, không sao chép thương hiệu hay nội dung thương mại. Thanh toán và ưu đãi thật chưa kết nối.')
a('2.9 Công cụ phát triển','Git quản lý mã nguồn; Flutter CLI chạy analyzer, test và build. Tài liệu repo hướng dẫn chạy local và ghi phạm vi. Build thành công chỉ chứng minh biên dịch, không chứng minh server hoặc nghiệp vụ production.')
a('2.10 Tiêu chí đánh giá','Đánh giá theo độ đầy đủ luồng, validation, lưu cùng browser, rõ trạng thái, responsive và test. Phân quyền server, booking đồng thời, khôi phục dữ liệu và thanh toán chưa có hạ tầng nên được ghi là giới hạn.')
a('CHƯƠNG 3. PHÂN TÍCH VÀ THIẾT KẾ','Chương này chuyển yêu cầu thành tác nhân, Stories, quy tắc, mô hình dữ liệu và sơ đồ UML rút gọn.')
a('3.1 Tác nhân','Khách tìm, xem, gửi/theo dõi đơn, yêu thích và đánh giá. Host/Admin quản lý homestay/phòng, duyệt đơn, lịch, bảo trì và số liệu. Vai trò demo nằm phía client nên không phải bảo mật thật.')
a('3.2 User Stories khách','User Story mô tả mục tiêu bằng ngôn ngữ nghiệp vụ. Tiêu chí chấp nhận cụ thể giúp tạo test.','Là khách, tôi muốn tìm theo điểm đến.|Tôi muốn lọc theo ngày và số khách.|Tôi muốn xem ảnh, tiện nghi, phòng và giá.|Tôi muốn gửi đơn và theo dõi trạng thái.|Tôi muốn lưu yêu thích và đánh giá sau lưu trú.')
a('3.3 User Stories quản trị','Quản trị làm việc theo homestay/phòng và giữ lịch sử booking. Thao tác thật cần ghi log ở server.','Tôi muốn thêm/sửa homestay.|Tôi muốn cấu hình phòng, giá và sức chứa.|Tôi muốn duyệt/từ chối đơn.|Tôi muốn xem lịch và bật bảo trì.|Tôi muốn xem số liệu theo kỳ.')
a('3.4 Ưu tiên Stories','P1 gồm khám phá, chi tiết, validation booking, xử lý trạng thái và quản lý phòng. P2 gồm yêu thích, review, lịch trực quan và biểu đồ. P3 gồm thanh toán, đồng bộ, push, bản đồ và AI online. Tiêu chí nghiệm thu nằm trong test/widget và phụ lục.')
a('3.5 Yêu cầu chức năng khách','Khách duyệt danh mục, tìm tên/khu vực, lọc tiện nghi/giá/sức chứa/ngày, xem chi tiết/phòng, chọn ngày/khách và gửi yêu cầu. Có thể xem đơn local và hủy theo trạng thái. Review chỉ sau hoàn thành; backend cần xác minh quyền.')
a('3.6 Yêu cầu Host/Admin','Quản trị demo thêm/sửa/xóa danh mục/phòng, cập nhật bảo trì, xem lịch, duyệt/từ chối đơn, check-in/out qua mã QR demo và xem thống kê. Thao tác tiền/role local không phải bảo mật.')
a('3.7 Yêu cầu phi chức năng','UI tiếng Việt, trạng thái loading/lỗi/rỗng, validation, responsive và phản hồi rõ. Availability, concurrency, backup, bảo mật production chưa đánh giá đủ vì chưa có server.')
a('3.8 Quy tắc ngày/sức chứa','Ngày trả phải sau ngày nhận; bản thử giới hạn 1–30 đêm, số khách dương và không quá sức chứa. Lịch kiểm tra các booking chiếm phòng. Test cùng isolate không chứng minh an toàn đa thiết bị.')
a('3.9 Mô hình dữ liệu','Các thực thể chính là User, Homestay, Room, Booking, Review và Repository. Homestay có nhiều phòng; phòng có booking theo thời gian; booking hoàn tất có thể có review. Snapshot giữ tên/giá lịch sử.','', 'class_diagram.png')
a('3.10 Use Case','Sơ đồ nhóm tác vụ theo Khách và Host/Admin. Vai trò chuyển ở client, nên đường biên bảo mật chỉ biểu diễn giao diện demo.','', 'use_case.png')
a('3.11 Activity đặt phòng','Khách tìm kiếm, chọn nơi/phòng, nhập ngày và số người, hệ thống kiểm tra, xem lại rồi lưu yêu cầu. Dữ liệu sai phải được phản hồi để khách sửa.','', 'activity_booking.png')
a('3.12 Sequence tạo đơn','UI gửi dữ liệu tới provider; repository kiểm tra nghiệp vụ và lưu SharedPreferences; kết quả được trả cho UI. Không có máy chủ hay transaction đa thiết bị trong chuỗi này.','', 'sequence_booking.png')
a('3.13 Trạng thái đơn','Model có pending, confirmed, checkedIn, checkedOut, rejected, cancelled và expired. Chỉ chuyển đổi phù hợp mới hợp lệ; ví dụ không check-out trước check-in hoặc duyệt đơn đã hết hạn.','', 'booking_states.png')
a('3.14 Điều hướng','Router nối landing/Home/Explore, chi tiết, booking, tài khoản và host. Duyệt danh mục công khai; gửi booking và mở trang tài khoản/quản trị yêu cầu phiên demo phù hợp vai trò. Bộ ảnh Phụ lục G ghi lại cả luồng khách lẫn các màn quản trị sau khi mở đúng phân hệ.')
a('3.15 Giao diện','Phong cách nền sáng, indigo/tím nhấn, card bo góc, ảnh lưu trú và badge trạng thái. Giá, ngày và số khách đặt cạnh thao tác đặt để giảm nhầm lẫn.')
a('3.16 Ảnh/tài nguyên','Album có 42 asset cục bộ, ba ảnh cho mỗi 14 homestay mẫu; test gallery xác nhận tệp được đóng gói và có thể chuyển ảnh. Có 41 ảnh được ghi rõ là ảnh tham khảo, chưa xác nhận thuộc đúng địa chỉ homestay; chỉ một ảnh có trạng thái xác minh nguồn địa điểm. Khi demo cần trình bày minh bạch chú thích nguồn ảnh.')
a('3.17 Thống kê','Dashboard tính số liệu từ booking/expense demo trên máy. Giá trị booking, tiền thực thu, công nợ và chi phí là khái niệm khác nhau; cần nhãn đúng. Chưa có thanh toán/đối soát ngân hàng.')
a('3.18 AI','Tài liệu ghi Gemini API khi cấu hình key và fallback cục bộ cho một số tư vấn. Thiếu key/hạn mức làm online unavailable. Key nhúng vào Flutter Web có thể bị trích xuất.')
a('CHƯƠNG 4. TRIỂN KHAI','Phần này trình bày tổ chức mã, môi trường và cách hiện thực các tác vụ.')
a('4.1 Công nghệ','Flutter/Dart, Riverpod, go_router, SharedPreferences. README nêu Flutter stable 3.35.2 và Dart 3.9.0 làm môi trường tham chiếu. Cần cố định phiên bản để tái lập build.')
a('4.2 Cấu trúc thư mục','Mã chính ở lib; model/repository chứa dữ liệu và nghiệp vụ; presentation chứa màn hình; router điều hướng; test chứa unit/widget tests; docs chứa đặc tả và hướng dẫn. homestay_app là bản khung cũ theo README.')
a('4.3 Khám phá','Explore lấy danh mục demo, áp dụng tìm kiếm, tiện nghi, giá, sức chứa, ngày và sắp xếp. Card mở trang chi tiết. Bộ ảnh hiện được đóng gói trong assets; test xác nhận có 42 ảnh đọc được từ bundle. Nguồn của 41 ảnh vẫn ở mức tham khảo và cần được xác minh quyền sử dụng/độ khớp với nơi nghỉ trước khi phát hành.')
a('4.4 Chi tiết phòng','Trang chi tiết trình bày thông tin, ảnh, tiện nghi, review và phòng. Phòng được chọn truyền sang bước booking. Giá/sức chứa cần lấy từ đúng phòng thay vì giá tổng quát.')
a('4.5 Tạo booking','Form nhận tên, ngày, số người và ghi chú. Repository kiểm tra ngày, sức chứa, bảo trì và chồng lấn rồi ghi local. Lỗi cũ “Chưa thể tạo đơn” là bằng chứng một lần thất bại; cần log hiện tại để xác định nguyên nhân, không suy rộng.')
a('4.6 Đơn của khách','Màn bookings đọc các đơn trong cùng browser storage, hiển thị trạng thái và hủy khi được phép. Browser quản trị khác không thấy đơn do không có đồng bộ máy chủ.')
a('4.7 Dashboard','Dashboard có chỉ số vận hành và biểu đồ booking demo. Số liệu chỉ là trạng thái local, không đại diện doanh thu thực hoặc nhiều cơ sở.')
a('4.8 Danh mục và phòng','Homestay là nơi lưu trú; phòng là đơn vị giá/sức chứa/khả dụng. Demo có tác vụ quản lý riêng. Chưa có upload ảnh cloud; cần nguồn file/URL hợp lệ cho ảnh mới.')
a('4.9 Lịch, bảo trì và QR','Lịch thể hiện ngày chiếm/trống; bảo trì chặn booking phù hợp. QR hiện chỉ là mã demo từ booking, không có token ngẫu nhiên, chữ ký server hay scanner online.')
a('4.10 Tài chính','Finance tổng hợp dữ liệu booking và chi phí local. Cần tách doanh thu ghi nhận, tiền đã thu, hoàn tiền và chi phí. Hiện chưa có chứng từ hoặc giao dịch thanh toán.')
a('4.11 Review và yêu thích','Yêu thích lưu local. Review gắn booking sau trả phòng. Production cần server xác minh chủ đơn và trạng thái, đồng thời giới hạn một review/booking.')
a('4.12 AI tư vấn','AI tùy thuộc cấu hình Gemini; thiếu key thì offline/chưa khả dụng. Request cần xử lý quota, mạng và lỗi API. Key browser không phải secret.')
a('4.13 Build web','Flutter build web tạo tài nguyên tĩnh; server cần SPA fallback và đúng base href/asset manifest. Localhost chỉ mở trên máy chạy server nếu không cấu hình mạng.')
a('4.14 Dữ liệu mẫu','Tài liệu ghi 14 homestay/điểm đến và 42 ảnh. Booking/favorite/CRUD lưu trên máy. Đây là dữ liệu minh họa, không phải chỗ nghỉ hay giao dịch thật.')
a('CHƯƠNG 5. KIỂM THỬ VÀ ĐÁNH GIÁ','Kết quả dưới đây phân biệt test hiện tại, quan sát browser và giới hạn chưa kiểm thử.')
a('5.1 Chiến lược test','Unit tests kiểm tra tính toán/trạng thái/repository; widget tests kiểm tra tương tác/UI; browser smoke test kiểm tra route và tài nguyên. Không có backend emulator nên không kết luận về server, quyền hoặc concurrency.')
a('5.2 Kết quả tự động','Ngày 23/10/2026 flutter analyze báo “No issues found”; flutter test báo “All tests passed!” với 96 test hoàn tất. Đây là bằng chứng cho ca tự động, không đảm bảo mọi tổ hợp production.')
a('5.3 Test luồng khách','Test bao phủ home, Explore, lọc, chi tiết, truyền ngày/khách, prefill tên, gửi một lần, review và responsive. Asset test đọc đủ 42 ảnh từ bundle; ảnh giao diện trong Phụ lục G được chụp ở kích thước 1280 × 720 trước khi đưa vào báo cáo.')
a('5.4 Test quản trị','Widget tests kiểm tra điều hướng quản trị, chỉ số dashboard, thêm homestay, duyệt booking, lịch và thao tác vận hành. Bộ ảnh Phụ lục G ghi nhận trang tổng quan quản trị, tài chính, lịch phòng và buồng phòng đang chạy trên localhost. Số liệu và thay đổi ở đây là dữ liệu demo lưu cục bộ; không đại diện giao dịch giữa nhiều người dùng.')
a('5.5 Test ngày và chồng lấn','Test kiểm tra khoảng ngày, sức chứa, bảo trì, hết hạn và trùng lịch cùng isolate. Đặc tả cảnh báo đây không phải giao dịch an toàn phân tán; production cần transaction server và test đồng thời.')
a('5.6 Test giao diện','Widget tests có ca bố cục hẹp 320px cho hồ sơ, lịch phòng và thao tác phòng. Ảnh Phụ lục G được chụp từ app chạy tại localhost ở 1280 × 720, bao gồm Home, Explore, chi tiết, booking, lịch sử, yêu thích, xác thực, hồ sơ, dashboard, tài chính, lịch, buồng phòng và trợ lý. Bộ ảnh chứng minh các màn hình đã được dựng; khả năng truy cập máy chủ, hiệu năng trên thiết bị và mọi trạng thái lỗi cần kiểm thử riêng.')
a('5.7 Xác thực','Tài liệu hiện hành nói phiên demo cục bộ, không Firebase Auth/server auth. Không thể khẳng định admin được bảo vệ trước sửa client hoặc dữ liệu an toàn. Không tạo tài khoản thật khi lập báo cáo.')
a('5.8 AI','Ảnh trợ lý ghi trạng thái offline/chưa khả dụng. Nguyên nhân có thể là key, quota, model hoặc mạng; chưa gọi online có key trong lần kiểm tra. Không lưu API key trong báo cáo.')
a('5.9 Rủi ro quan sát','Dữ liệu lưu trên trình duyệt không đồng bộ nhiều thiết bị và không bảo đảm giao dịch thật; AI online phụ thuộc API key, quyền project, mạng và hạn mức. Quản trị local giúp trình diễn luồng, nhưng không thay thế xác thực hay phân quyền phía máy chủ. Các giới hạn này được ghi rõ để không nhầm prototype với dịch vụ đã vận hành.')
a('5.10 Mức độ đáp ứng đề bài','Báo cáo đối chiếu từng nội dung đọc được trên bảng: User Stories; phân tích tác nhân, quan hệ và nghiệp vụ; một Class Diagram; bảy sơ đồ Activity/Sequence (ba Activity, bốn Sequence); thiết kế màn hình bằng ảnh app và Flow of Work. Chưa có file Figma riêng trong repository; nếu giảng viên yêu cầu bản Figma có thể chỉnh sửa, nhóm cần bổ sung file/link riêng.')
a('5.11 Giới hạn đánh giá','Không có user thật, backend, cổng thanh toán hoặc đa thiết bị. Browser smoke test chỉ một môi trường. Test pass không chứng minh đã chạy mọi tác vụ với tài khoản thực.')
a('CHƯƠNG 6. KẾT LUẬN','Nhóm đã xây dựng prototype cho khám phá, chi tiết, booking demo và quản trị local. Lần kiểm tra 23/10/2026, flutter analyze không phát hiện vấn đề và 96 test tự động đều qua. Kết quả chứng minh các ca đã kiểm thử trong phạm vi local, không chứng nhận backend hoặc vận hành production.')
a('6.1 Kết luận','Cấu trúc provider/repository hỗ trợ kiểm thử và thay đổi data source. Prototype đáp ứng trình diễn các luồng khách và host, đồng thời báo cáo phân biệt dữ liệu demo với tính năng chưa có ở môi trường thật. Trước triển khai thực tế cần backend, xác thực/phân quyền máy chủ, giao dịch đặt phòng đồng thời, thanh toán và xác minh ảnh.')
a('6.2 Ưu tiên ngắn hạn','Giữ nhãn dữ liệu mẫu rõ ràng; tiếp tục thử luồng trên profile trình duyệt sạch và lưu ảnh minh chứng có ngày chụp. Trước buổi bảo vệ, nhập đúng tên giảng viên và thống nhất tỷ lệ đóng góp thực tế của từng thành viên. Không đưa khóa API hoặc dữ liệu cá nhân vào báo cáo.')
a('6.3 Backend tương lai','Thêm Auth/Firestore hoặc API, rules, transaction booking, image storage và emulator tests. Đưa quyền, giá, QR, tiền nhạy cảm lên server; thử hai yêu cầu đặt trùng đồng thời.')
a('6.4 Vận hành tương lai','Bổ sung duyệt homestay, lịch bảo trì, audit check-in/out, báo cáo theo kỳ và khoản thu/chi có chứng từ. Định nghĩa rõ doanh thu, tiền thu, công nợ và giá trị booking.')
a('6.5 Chất lượng tương lai','Mở rộng accessibility, test e2e, responsive trên thiết bị và crash monitoring. Cần test Android/iOS riêng nếu nằm trong phạm vi; kết quả web không đại diện mobile.')
a('TÀI LIỆU THAM KHẢO','Ngày truy cập 23/10/2026.','Flutter Documentation — https://docs.flutter.dev/learn|Flutter Architecture — https://docs.flutter.dev/resources/architectural-overview|Riverpod — https://riverpod.dev/docs/concepts2/providers|SharedPreferences — https://pub.dev/packages/shared_preferences|Gemini API — https://ai.google.dev/api/generate-content|HHL Stay README.md, docs/dac-ta-app.md, docs/chay-ban-thu.md, docs/kiem-thu-ban-dau.md')
a('PHỤ LỤC A. Hướng dẫn chạy','Tại thư mục dự án, tải packages và chạy web server local.','flutter pub get|flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8083|Mở http://127.0.0.1:8083|Chạy flutter analyze; flutter test; flutter build web|Không commit Gemini key')
a('PHỤ LỤC A. Tài liệu nội bộ','README mô tả cách chạy; đặc tả nêu quy tắc; hướng dẫn demo mô tả use case; tài liệu thiết kế ghi nguồn ảnh; kết quả test lưu lịch sử.','README.md|docs/dac-ta-app.md|docs/chay-ban-thu.md|docs/thiet-ke-giao-dien.md|docs/kiem-thu-ban-dau.md|docs/nguon-anh.md')
a('PHỤ LỤC B. Kết quả kiểm thử','Workspace 23/10/2026: analyzer không lỗi, 96 test pass. Test cô lập không kiểm backend hay đồng thời nhiều thiết bị.')
a('PHỤ LỤC B. Ma trận kiểm thử','Các ca và bằng chứng test.','Admin navigation không có Explore: test widget|Home mở Explore: test widget|Booking truyền dữ liệu và gửi một lần: test repository/widget|Thêm homestay cập nhật catalog: test widget|Duyệt booking cập nhật trạng thái: test repository/widget|Lịch/bảo trì và responsive: test widget|42 asset có thể đọc từ bundle; 41 ảnh chỉ mang tính tham khảo')
a('PHỤ LỤC C. Đối chiếu yêu cầu cô','Bảng trên lớp yêu cầu Project User Stories; phân tích đối tượng, quan hệ và phương thức hoạt động; một Class Diagram; hơn bốn Sequence/Activity Diagrams; screens/wireframes/mockups và Flow of Work.','User Stories: Chương 3.2–3.4 và Bảng F.1|Actor/quan hệ: Chương 3.1, 3.5–3.9 và Bảng F.3|Class Diagram: Hình 3.1|Sequence/Activity: Hình 3.3, 3.4, 3.6–3.10; tổng cộng 7 sơ đồ quy trình|Vòng đời booking: Hình 3.5|Screens app: Phụ lục G|Flow of Work: Hình C.1, Phụ lục C|File Figma chỉnh sửa riêng: chưa có trong repository')
a('PHỤ LỤC C. Flow of Work','Nhóm bắt đầu từ yêu cầu và User Stories, phân tích tác nhân/quy tắc, dựng model cùng UML, thiết kế màn hình, triển khai UI và repository, rồi kiểm thử, build và chụp minh chứng. Kết quả kiểm thử quay lại backlog để sửa. Hình C.1 thể hiện vòng công việc đã áp dụng cho prototype.','', 'workflow.png')
a('PHỤ LỤC D. Thuật ngữ','Homestay: nơi nghỉ; Room: phòng; Booking: yêu cầu lưu trú; ADR/RevPAR: chỉ số phòng khi đủ dữ liệu; Local demo: dữ liệu trên thiết bị; Prototype: bản thử ý tưởng và luồng.')
# diagrams drawn with Pillow
def draw(name,title,items,edges):
 im=Image.new('RGB',(1400,760),'#fdfdff'); from PIL import ImageDraw,ImageFont
 d=ImageDraw.Draw(im)
 for gx in range(0,1400,24): d.line((gx,0,gx,760),fill='#eeeeF5' if gx%120 else '#e4e3ef',width=1)
 for gy in range(0,760,24): d.line((0,gy,1400,gy),fill='#eeeeF5' if gy%120 else '#e4e3ef',width=1)
 f=ImageFont.truetype('C:/Windows/Fonts/times.ttf',23); fb=ImageFont.truetype('C:/Windows/Fonts/timesbd.ttf',30); d.text((40,25),title,font=fb,fill='#111827'); pos={}
 for key,x,y,w,h,label in items:
  pos[key]=(x,y,w,h)
  if name=='class_diagram':
   d.rounded_rectangle((x,y,x+w,y+h),radius=8,fill='#ffffff',outline='#625ab8',width=2); d.rectangle((x,y,x+w,y+50),fill='#ebe9ff',outline='#625ab8',width=2); d.line((x,y+50,x+w,y+50),fill='#625ab8',width=1)
   ls=label.split('\n'); bb=d.textbbox((0,0),ls[0],font=fb); d.text((x+(w-bb[2]+bb[0])/2,y+7),ls[0],font=fb,fill='#172033'); yy=y+62; usefont=f
  elif name=='use_case' and key in ('g','a'):
   cx=x+w/2; cy=y+h/2-12; d.ellipse((cx-17,cy-42,cx+17,cy-8),outline='#625ab8',width=2); d.line((cx,cy-8,cx,cy+26),fill='#625ab8',width=2); d.line((cx-22,cy+4,cx+22,cy+4),fill='#625ab8',width=2); d.line((cx,cy+26,cx-18,cy+47),fill='#625ab8',width=2); d.line((cx,cy+26,cx+18,cy+47),fill='#625ab8',width=2); ls=[label]; yy=y+h-24; usefont=f
  elif name=='use_case':
   d.ellipse((x,y,x+w,y+h),fill='#f5f3ff',outline='#625ab8',width=2); ls=label.split('\n'); yy=y+(h-len(ls)*30)//2; usefont=f
  elif name.startswith('activity_') and key in ('s','a'):
   d.ellipse((x,y,x+w,y+h),fill='#f5f3ff',outline='#625ab8',width=2); d.ellipse((x+w*.3,y+h*.3,x+w*.7,y+h*.7),fill='#625ab8'); ls=[]; yy=y; usefont=f
  elif name.startswith('activity_') and key in ('check','r','verify'):
   d.polygon([(x+w/2,y),(x+w,y+h/2),(x+w/2,y+h),(x,y+h/2)],fill='#f5f3ff',outline='#625ab8'); d.line([(x+w/2,y),(x+w,y+h/2),(x+w/2,y+h),(x,y+h/2),(x+w/2,y)],fill='#625ab8',width=2); ls=label.split('\n'); yy=y+(h-len(ls)*30)//2; usefont=f
  else:
   d.rounded_rectangle((x,y,x+w,y+h),radius=14,fill='#f5f3ff',outline='#625ab8',width=2); ls=label.split('\n'); yy=y+(h-len(ls)*30)//2; usefont=f
  if name=='class_diagram': ls=label.split('\n')[1:]; yy=y+61
  for z in ls: bb=d.textbbox((0,0),z,font=usefont); d.text((x+(w-bb[2]+bb[0])/2,yy),z,font=usefont,fill='#172033'); yy+=30
 if name.startswith('sequence_'):
  im=Image.new('RGB',(1400,760),'#fdfdff'); d=ImageDraw.Draw(im)
  for gx in range(0,1400,24): d.line((gx,0,gx,760),fill='#eeeeF5' if gx%120 else '#e4e3ef',width=1)
  for gy in range(0,760,24): d.line((0,gy,1400,gy),fill='#eeeeF5' if gy%120 else '#e4e3ef',width=1)
  d.text((40,25),title,font=fb,fill='#111827'); participants=items[:4]; centers=[]
  for key,x,y,w,h,label in participants:
   cx=x+w/2; centers.append(cx); rect=(cx-125,90,250,68); d.rounded_rectangle((rect[0],rect[1],rect[0]+rect[2],rect[1]+rect[3]),radius=8,fill='#f5f3ff',outline='#625ab8',width=2)
   bb=d.textbbox((0,0),label,font=f); d.text((cx-(bb[2]-bb[0])/2,112),label,font=f,fill='#172033')
   for ly in range(160,630,22): d.line((cx,ly,cx,ly+10),fill='#8985b3',width=1)
  seqedges=[(aa,bb,lab) for aa,bb,lab in edges if aa in {x[0] for x in participants} and bb in {x[0] for x in participants}]
  for j,(aa,bb,lab) in enumerate(seqedges):
   ia=next(i for i,x in enumerate(participants) if x[0]==aa); ib=next(i for i,x in enumerate(participants) if x[0]==bb); y=205+j*72; xa,xb=centers[ia],centers[ib]; direction=1 if xb>=xa else -1; start=xa+direction*7; end=xb-direction*7
   if ia==ib: d.line((xa,y,xa+44,y),fill='#625ab8',width=2); d.line((xa+44,y,xa+44,y+30),fill='#625ab8',width=2); d.line((xa+44,y+30,xa,y+30),fill='#625ab8',width=2); d.polygon([(xa,y+30),(xa+10,y+24),(xa+10,y+36)],fill='#625ab8'); y+=15
   else:
    d.line((start,y,end,y),fill='#625ab8',width=2)
    d.polygon([(end,y),(end-direction*12,y-6),(end-direction*12,y+6)],fill='#625ab8')
   if lab:
    bbx=d.textbbox((0,0),lab,font=f); tx=(xa+xb)/2-(bbx[2]-bbx[0])/2; d.rectangle((tx-5,y-30,tx+bbx[2]-bbx[0]+5,y-4),fill='#fdfdff'); d.text((tx,y-30-bbx[1]),lab,font=f,fill='#374151')
  result=items[4][5] if len(items)>4 else 'Hoàn tất'
  d.rounded_rectangle((425,660,975,722),radius=11,fill='#f5f3ff',outline='#625ab8',width=2); bb=d.textbbox((0,0),result,font=f); d.text((700-(bb[2]-bb[0])/2,681-bb[1]),result,font=f,fill='#172033')
  d.line((centers[2],620,centers[2],642),fill='#8985b3',width=1); d.line((centers[2],642,700,642),fill='#8985b3',width=1); d.line((700,642,700,660),fill='#8985b3',width=1)
  im.save(OUT/(name+'.png')); return
 for aa,bb,lab in edges:
  import math
  x,y,w,h=pos[aa]; X,Y,W,H=pos[bb]; p=(x+w/2,y+h/2); q=(X+W/2,Y+H/2); dx=q[0]-p[0]; dy=q[1]-p[1]; length=max(1,(dx*dx+dy*dy)**.5); ux,uy=dx/length,dy/length
  s=min((w/2-5)/abs(ux) if abs(ux)>1e-6 else 1e9,(h/2-5)/abs(uy) if abs(uy)>1e-6 else 1e9)
  t=min((W/2-8)/abs(ux) if abs(ux)>1e-6 else 1e9,(H/2-8)/abs(uy) if abs(uy)>1e-6 else 1e9)
  start=(p[0]+ux*s,p[1]+uy*s); end=(q[0]-ux*t,q[1]-uy*t); d.line((start,end),fill='#64748b',width=2)
  ang=math.atan2(end[1]-start[1],end[0]-start[0]); back=(end[0]-12*math.cos(ang),end[1]-12*math.sin(ang)); l=(back[0]+6*math.cos(ang+2.45),back[1]+6*math.sin(ang+2.45)); r=(back[0]+6*math.cos(ang-2.45),back[1]+6*math.sin(ang-2.45)); d.polygon([end,l,r],fill='#64748b')
 im.save(OUT/(name+'.png'))
draw('class_diagram','Class Diagram HHL Stay',[('u',30,170,250,170,'User\nuserId, role, name'),('h',390,80,280,190,'Homestay\nid, location, images'),('r',850,80,260,190,'Room\nhomeId, capacity, price'),('b',850,430,280,190,'Booking\nguest, dates, status'),('v',390,430,280,190,'Review\nbooking, rating'),('repo',30,430,250,170,'Repository\nload/save')],[('u','b','creates'),('h','r','1..*'),('r','b','has'),('b','v','completed'),('repo','h','stores'),('repo','b','stores')])
draw('use_case','Use Case Khách và Host/Admin',[('g',40,300,230,110,'Khách'),('a',40,520,230,110,'Host/Admin'),('s',400,130,350,100,'Tìm kiếm và xem'),('b',400,300,350,100,'Đặt/theo dõi/hủy'),('rev',400,470,350,100,'Đánh giá'),('m',940,160,400,100,'Quản lý homestay/phòng'),('o',940,340,400,100,'Duyệt, lịch, bảo trì'),('f',940,520,400,100,'Thống kê tài chính demo')],[('g','s',''),('g','b',''),('g','rev',''),('a','m',''),('a','o',''),('a','f','')])
draw('activity_booking','Activity: gửi yêu cầu đặt phòng',[('s',30,300,190,100,'Bắt đầu'),('find',280,300,230,100,'Tìm chỗ nghỉ'),('room',580,300,240,100,'Chọn phòng/ngày'),('check',900,130,300,120,'Kiểm tra ngày\nsức chứa/lịch'),('submit',900,450,300,120,'Xem lại/gửi'),('done',580,500,240,100,'Lưu demo'),('end',280,550,230,100,'Kết thúc')],[('s','find',''),('find','room',''),('room','check',''),('check','submit','hợp lệ'),('submit','done',''),('done','end','')])
draw('sequence_booking','Sequence: lưu booking local',[('ui',30,170,250,110,'UI Khách'),('state',340,170,250,110,'Riverpod'),('repo',670,170,260,110,'Repository'),('prefs',1030,170,300,110,'SharedPreferences'),('res',520,530,350,110,'Kết quả/thông báo')],[('ui','state','1 dữ liệu'),('state','repo','2 validate'),('repo','prefs','3 ghi'),('prefs','repo','4 kết quả'),('repo','res','5 phản hồi')])
draw('booking_states','Vòng đời booking',[('p',40,300,200,110,'Chờ duyệt'),('c',340,300,220,110,'Xác nhận'),('i',680,300,220,110,'Lưu trú'),('o',1050,300,250,110,'Đã trả'),('x',340,540,220,90,'Từ chối/hủy'),('e',40,540,200,90,'Hết hạn')],[('p','c','duyệt'),('p','x','từ chối'),('p','e','quá hạn'),('c','i','check-in'),('i','o','check-out')])
# Additional behavioral models requested by the course rubric (>4 sequence/activity diagrams).
draw('activity_search','Activity: tìm kiếm và lọc',[('s',30,300,190,100,'Bắt đầu'),('q',300,300,230,100,'Nhập nơi/ngày'),('f',600,300,240,100,'Áp dụng bộ lọc'),('r',930,300,250,100,'Xem kết quả'),('e',1170,540,180,90,'Mở chi tiết'),('empty',600,540,240,90,'Điều chỉnh lọc')],[('s','q',''),('q','f',''),('f','r',''),('r','e','có kết quả'),('r','empty','rỗng')])
draw('activity_checkin','Activity: nhận và trả phòng',[('a',30,300,190,100,'Bắt đầu'),('find',290,300,230,100,'Tìm booking'),('verify',600,300,250,100,'Kiểm tra mã/ngày'),('in',960,140,240,100,'Ghi nhận check-in'),('stay',960,330,240,100,'Đang lưu trú'),('out',960,520,240,100,'Ghi nhận check-out')],[('a','find',''),('find','verify',''),('verify','in','hợp lệ'),('in','stay',''),('stay','out','đến ngày trả')])
draw('sequence_approval','Sequence: quản trị duyệt booking',[('host',30,150,220,100,'Host UI'),('state',320,150,220,100,'Provider'),('repo',620,150,240,100,'Repository'),('storage',960,150,300,100,'Local storage'),('result',490,520,330,100,'Trạng thái mới')],[('host','state','1 chọn duyệt'),('state','repo','2 kiểm tra quyền demo'),('repo','storage','3 cập nhật'),('storage','repo','4 xác nhận'),('repo','result','5 trả kết quả')])
draw('sequence_review','Sequence: gửi đánh giá',[('guest',30,150,220,100,'Khách UI'),('provider',320,150,220,100,'Provider'),('repo',620,150,240,100,'Review repo'),('store',960,150,300,100,'Local storage'),('done',490,520,330,100,'Hiện đánh giá')],[('guest','provider','1 nhập sao/nội dung'),('provider','repo','2 kiểm tra đơn hoàn tất'),('repo','store','3 lưu review'),('store','repo','4 trả dữ liệu'),('repo','done','5 cập nhật điểm')])
draw('sequence_finance','Sequence: tổng hợp báo cáo tài chính demo',[('admin',30,150,220,100,'Admin UI'),('filter',320,150,220,100,'Chọn kỳ'),('repo',620,150,240,100,'Finance repo'),('data',960,150,300,100,'Booking + expense'),('chart',490,520,330,100,'KPI và biểu đồ')],[('admin','filter','1 yêu cầu'),('filter','repo','2 kỳ báo cáo'),('repo','data','3 đọc dữ liệu local'),('data','repo','4 tổng hợp'),('repo','chart','5 hiển thị')])
draw('workflow','Flow of Work HHL Stay',[('req',25,150,270,100,'Yêu cầu đề bài'),('story',370,150,270,100,'User Stories'),('analysis',715,150,270,100,'Actor + quy tắc'),('design',1060,150,300,100,'Model + UML + UI'),('code',1060,480,300,100,'Flutter + repository'),('test',715,480,270,100,'Review + test'),('build',370,480,270,100,'Build web'),('demo',25,480,270,100,'Chụp minh chứng')],[('req','story',''),('story','analysis',''),('analysis','design',''),('design','code',''),('code','test',''),('test','build',''),('build','demo','')])
for title,body,im in [
 ('PHỤ LỤC E.1 Activity tìm kiếm','Khách nhập địa điểm và điều kiện lưu trú, áp dụng bộ lọc rồi kiểm tra kết quả. Khi không có kết quả, ứng dụng cần cho phép điều chỉnh điều kiện thay vì để người dùng ở trạng thái cụt.','activity_search'),
 ('PHỤ LỤC E.2 Activity nhận và trả phòng','Quản trị tìm booking, xác minh mã và ngày lưu trú, rồi ghi nhận check-in/check-out. Bản demo chỉ kiểm tra nội bộ; hệ thống thật cần server xác minh và nhật ký thao tác.','activity_checkin'),
 ('PHỤ LỤC E.3 Sequence duyệt booking','Host chọn hành động trên giao diện; provider gọi repository; repository kiểm tra điều kiện rồi cập nhật storage local. Kết quả được phản hồi lại để danh sách và dashboard dựng lại.','sequence_approval'),
 ('PHỤ LỤC E.4 Sequence đánh giá','Khách gửi điểm và nhận xét; hệ thống kiểm tra booking đã hoàn tất, lưu review và cập nhật danh sách/điểm trung bình. Ràng buộc chủ đơn phải được kiểm tra lại ở server khi có backend.','sequence_review'),
 ('PHỤ LỤC E.5 Sequence báo cáo tài chính','Quản trị chọn kỳ; repository đọc booking và expense demo, tổng hợp chỉ số rồi trả cho UI hiển thị KPI/biểu đồ. Chỉ số phụ thuộc dữ liệu local và định nghĩa kỳ.','sequence_finance')]:
 a(title,body,'',im+'.png')
# create docx
D=Document(); sec=D.sections[0]; sec.page_width=Cm(21.59); sec.page_height=Cm(27.94); sec.top_margin=Cm(2.54); sec.bottom_margin=Cm(2.54); sec.left_margin=Cm(2.54); sec.right_margin=Cm(2.54); sec.different_first_page_header_footer=True
for sn in ['Normal','Body Text']:
 st=D.styles[sn]; st.font.name='Times New Roman'; st.font.size=Pt(12); st._element.rPr.rFonts.set(qn('w:eastAsia'),'Times New Roman'); st.paragraph_format.line_spacing=1.2; st.paragraph_format.space_after=Pt(6)
for sn,size in [('Title',22),('Heading 1',16)]:
 st=D.styles[sn]; st.font.name='Times New Roman'; st.font.size=Pt(size); st.font.bold=True; st.font.color.rgb=RGBColor(0,0,0); st._element.rPr.rFonts.set(qn('w:eastAsia'),'Times New Roman')
hd=sec.header.paragraphs[0]; hd.text=''
ft=sec.footer.paragraphs[0]; ft.alignment=WD_ALIGN_PARAGRAPH.CENTER; fld=OxmlElement('w:fldSimple'); fld.set(qn('w:instr'),'PAGE'); ft._p.append(fld)
sec.first_page_footer.paragraphs[0].text=''
def center(s,size,bold=False):
 p=D.add_paragraph(); p.alignment=WD_ALIGN_PARAGRAPH.CENTER; r=p.add_run(s); r.font.name='Times New Roman'; r.font.size=Pt(size); r.bold=bold; return p
cover=D.add_paragraph(); cover.paragraph_format.space_before=Pt(24); cover.paragraph_format.line_spacing=1.35; rr=cover.add_run('ĐẠI HỌC PHENIKAA\nTRƯỜNG CÔNG NGHỆ THÔNG TIN PHENIKAA'); rr.font.name='Times New Roman'; rr.font.size=Pt(14)
logo=AS/'phenikaa_faculty_logo.png'
if logo.exists():
 lp=D.add_paragraph(); lp.paragraph_format.left_indent=Cm(.7); lp.paragraph_format.space_before=Pt(18); lp.paragraph_format.space_after=Pt(20); lp.add_run().add_picture(str(logo),width=Cm(5.2))
p=D.add_paragraph(); p.paragraph_format.space_before=Pt(8); r=p.add_run('BÁO CÁO ĐỒ ÁN CƠ SỞ\nĐỀ TÀI: XÂY DỰNG ỨNG DỤNG QUẢN LÝ HOMESTAY HHL STAY'); r.font.name='Times New Roman'; r.font.size=Pt(14)
p=D.add_paragraph(); p.paragraph_format.space_before=Pt(24); p.add_run('Giảng viên hướng dẫn: ........................................................').font.size=Pt(12)
p=D.add_paragraph(); p.paragraph_format.space_before=Pt(18); p.alignment=WD_ALIGN_PARAGRAPH.CENTER; p.add_run('Thành viên nhóm:\nPhạm Văn Huấn — 23010331\nNguyễn Hữu Lê Hiếu — 23010985\nNguyễn Hải Long — 2301872').font.size=Pt(12)
p=D.add_paragraph(); p.paragraph_format.space_before=Pt(30); p.add_run('Hà Nội, 10/2026').font.size=Pt(12)
D.add_page_break()
team_title=D.add_paragraph(); team_title.alignment=WD_ALIGN_PARAGRAPH.CENTER; team_title.paragraph_format.space_after=Pt(18)
team_run=team_title.add_run('DANH SÁCH VÀ NHIỆM VỤ CÁC THÀNH VIÊN TRONG NHÓM')
team_run.bold=True; team_run.font.name='Times New Roman'; team_run.font.size=Pt(14)
team_rows=[
 ('Họ tên / Mã sinh viên','Nhiệm vụ ghi nhận trong sản phẩm','Tỷ lệ đóng góp'),
 ('Phạm Văn Huấn\n23010331','Cập nhật README và tài liệu hướng dẫn dự án.','Nhóm xác nhận'),
 ('Nguyễn Hữu Lê Hiếu\n23010985','Phát triển ứng dụng, luồng khách và quản trị, lưu trữ demo, AI, kiểm thử và báo cáo.','Nhóm xác nhận'),
 ('Nguyễn Hải Long\n2301872','Khởi tạo và đưa project lên repository, phối hợp tích hợp mã nguồn.','Nhóm xác nhận'),
]
team_table=D.add_table(rows=0,cols=3); team_table.style='Table Grid'; team_table.alignment=WD_TABLE_ALIGNMENT.CENTER
for ridx,row in enumerate(team_rows):
 cells=team_table.add_row().cells
 for cidx,value in enumerate(row):
  cells[cidx].text=value; cells[cidx].vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
  for para in cells[cidx].paragraphs:
   para.paragraph_format.space_after=Pt(4); para.paragraph_format.space_before=Pt(4)
   for run in para.runs:
    run.font.name='Times New Roman'; run.font.size=Pt(10.5); run.bold=(ridx==0)
 for cell,width in zip(cells,[Cm(4.1),Cm(9.0),Cm(3.2)]): cell.width=width
note=D.add_paragraph('Nhiệm vụ trên được tổng hợp từ nội dung repository. Tỷ lệ đóng góp cần được cả nhóm xác nhận theo công việc thực tế trước khi nộp.')
note.paragraph_format.space_before=Pt(14); note.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
for run in note.runs: run.font.name='Times New Roman'; run.font.size=Pt(10)
D.add_page_break()
for idx,(title,txt,bul,img) in enumerate(P):
 chapter=title.startswith('CHƯƠNG ') or title in ['TÀI LIỆU THAM KHẢO'] or title.startswith('PHỤ LỤC ')
 hp=D.add_paragraph(); hp.paragraph_format.keep_with_next=True; hp.paragraph_format.space_before=Pt(4); hp.paragraph_format.space_after=Pt(5)
 hp.alignment=WD_ALIGN_PARAGRAPH.CENTER if title.startswith('CHƯƠNG ') or title=='TÀI LIỆU THAM KHẢO' else WD_ALIGN_PARAGRAPH.LEFT
 hr=hp.add_run(title); hr.font.name='Times New Roman'; hr.font.bold=True; hr.font.color.rgb=RGBColor(0,0,0); hr.font.size=Pt(14 if title.startswith('CHƯƠNG ') or title=='TÀI LIỆU THAM KHẢO' else 12)
 p=D.add_paragraph(txt); p.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
 if img: p.paragraph_format.keep_with_next=True
 for b in bul:
  if title in ['Mục lục và quy ước','Danh mục hình và bảng']:
   p=D.add_paragraph(); p.paragraph_format.left_indent=Cm(.15); p.paragraph_format.space_after=Pt(2); p.paragraph_format.tab_stops.add_tab_stop(Cm(15.6),WD_TAB_ALIGNMENT.RIGHT,WD_TAB_LEADER.DOTS)
   import re
   m=re.match(r'^(.*?)(?:\s*\.+\s*(\d+(?:–\d+)?))$',b)
   p.add_run((m.group(1).rstrip() if m else b)+'\t'+(m.group(2) if m else ''))
  else:
   p=D.add_paragraph(style='List Bullet'); p.paragraph_format.left_indent=Cm(.7); p.add_run(b)
 if img:
  p=D.add_paragraph(); p.alignment=WD_ALIGN_PARAGRAPH.CENTER; p.paragraph_format.keep_with_next=True; p.add_run().add_picture(str(OUT/(img if img.endswith('.png') else img+'.png')),width=Cm(14.1))
  captions={'class_diagram.png':'Hình 3.1. Sơ đồ lớp dữ liệu HHL Stay.','use_case.png':'Hình 3.2. Sơ đồ Use Case theo tác nhân.','activity_booking.png':'Hình 3.3. Sơ đồ hoạt động gửi yêu cầu đặt phòng.','sequence_booking.png':'Hình 3.4. Sơ đồ tuần tự tạo yêu cầu đặt phòng.','booking_states.png':'Hình 3.5. Vòng đời trạng thái booking.','activity_search.png':'Hình 3.6. Sơ đồ hoạt động tìm kiếm và lọc.','activity_checkin.png':'Hình 3.7. Sơ đồ hoạt động nhận và trả phòng.','sequence_approval.png':'Hình 3.8. Sơ đồ tuần tự duyệt booking.','sequence_review.png':'Hình 3.9. Sơ đồ tuần tự gửi đánh giá.','sequence_finance.png':'Hình 3.10. Sơ đồ tuần tự tổng hợp tài chính.','workflow.png':'Hình C.1. Quy trình thực hiện và kiểm tra HHL Stay.'}
  p=D.add_paragraph(captions.get(img,'Hình minh họa quy trình của HHL Stay.')); p.alignment=WD_ALIGN_PARAGRAPH.CENTER; p.paragraph_format.keep_together=True
  for r in p.runs: r.italic=True; r.font.size=Pt(10)
 if idx % 2 == 1 and not (P[idx][3] or P[idx-1][3]): D.add_page_break()

# Supplementary matrices provide traceable detail without presenting the local
# prototype as a production booking service.
def _shade(cell, color):
 tcPr=cell._tc.get_or_add_tcPr(); shd=OxmlElement('w:shd'); shd.set(qn('w:fill'),color); tcPr.append(shd)
def _cant_split(row):
 trPr=row._tr.get_or_add_trPr(); el=OxmlElement('w:cantSplit'); trPr.append(el)
def _repeat_header(row):
 trPr=row._tr.get_or_add_trPr(); el=OxmlElement('w:tblHeader'); el.set(qn('w:val'),'true'); trPr.append(el)
def add_matrix(title, caption, intro, headers, rows, widths):
 D.add_page_break()
 hp=D.add_paragraph(); hp.paragraph_format.keep_with_next=True; hp.paragraph_format.space_after=Pt(4)
 rr=hp.add_run(title); rr.font.name='Times New Roman'; rr.bold=True; rr.font.size=Pt(12); rr.font.color.rgb=RGBColor(0,0,0)
 ip=D.add_paragraph(intro); ip.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY; ip.paragraph_format.keep_with_next=True
 cp=D.add_paragraph(); cp.alignment=WD_ALIGN_PARAGRAPH.CENTER; cp.paragraph_format.keep_with_next=True
 cr=cp.add_run(caption); cr.font.name='Times New Roman'; cr.font.size=Pt(10); cr.bold=True
 table=D.add_table(rows=1,cols=len(headers)); table.style='Table Grid'; table.alignment=WD_TABLE_ALIGNMENT.CENTER; table.autofit=False
 _repeat_header(table.rows[0])
 for i,label in enumerate(headers):
  c=table.rows[0].cells[i]; c.width=Cm(widths[i]); c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER; _shade(c,'E9E7F4')
  c.text=label
 for row in rows:
  cells=table.add_row().cells; _cant_split(table.rows[-1])
  for i,value in enumerate(row): cells[i].text=str(value); cells[i].width=Cm(widths[i]); cells[i].vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
 for ri,row in enumerate(table.rows):
  for i,c in enumerate(row.cells):
   c.width=Cm(widths[i])
   for p0 in c.paragraphs:
    p0.paragraph_format.space_after=Pt(1); p0.paragraph_format.space_before=Pt(1); p0.paragraph_format.line_spacing=1.0
    for run in p0.runs:
     run.font.name='Times New Roman'; run._element.rPr.rFonts.set(qn('w:eastAsia'),'Times New Roman'); run.font.size=Pt(9)
     if ri == 0: run.bold=True

tables=[
('PHỤ LỤC F.1 User Stories và tiêu chí chấp nhận','Bảng F.1. User Stories của khách và người vận hành',
 'Các câu chuyện mô tả giá trị người dùng và điều kiện để luồng được xem là hoàn tất. Trạng thái “demo local” nhấn mạnh rằng xác thực, dữ liệu và quyền hiện lưu trên thiết bị, không phải dịch vụ production.',
 ['Mã','Vai trò / nhu cầu','Tiêu chí chấp nhận','Phạm vi hiện tại'],[
 ('US-G01','Khách tạo tài khoản và đăng nhập','Bắt buộc tên, email hợp lệ, mật khẩu đạt điều kiện; phiên được phục hồi trên cùng trình duyệt.','Demo local'),
 ('US-G02','Khách khám phá điểm đến','Xem nhóm điểm đến và danh sách lưu trú; ảnh, tên và giá đọc được.','Có'),
 ('US-G03','Khách tìm và lọc nơi nghỉ','Tìm tên/khu vực và lọc theo điều kiện có trong UI; kết quả rỗng cho phép đổi điều kiện.','Có'),
 ('US-G04','Khách xem chi tiết phòng','Xem mô tả, ảnh, tiện nghi, sức chứa, giá/phòng và đánh giá.','Có'),
 ('US-G05','Khách lưu nơi yêu thích','Thêm/bỏ yêu thích; dữ liệu tách theo tài khoản demo và tồn tại sau reload.','Local storage'),
 ('US-G06','Khách chọn ngày/số người','Chọn khoảng [nhận, trả), ít nhất một đêm và không quá 30 đêm; số khách không vượt sức chứa.','Có kiểm tra'),
 ('US-G07','Khách gửi yêu cầu đặt','Phải đăng nhập bằng vai trò Guest; xem lại giá và ngày trước khi xác nhận gửi.','Có'),
 ('US-G08','Khách nhận ưu đãi demo','Thành viên áp dụng 5%; mã HHL10 thêm 10%; tổng giảm không vượt 100%.','Không phải mã thật'),
 ('US-G09','Khách tránh đặt trùng','Phòng bảo trì hoặc khoảng ngày xung đột không nhận booking mới.','Kiểm tra cục bộ'),
 ('US-G10','Khách theo dõi/hủy đơn','Xem mã, ngày, tổng tiền và trạng thái; hủy chỉ khi trạng thái/chính sách cho phép.','Có'),
 ('US-G11','Khách đánh giá kỳ nghỉ','Chỉ chủ đơn có booking đã check-out được gửi một đánh giá; review lưu theo booking.','Demo local'),
 ('US-G12','Khách hỏi trợ lý lưu trú','Offline trả lời từ catalog đã có; Gemini chỉ hoạt động khi cấu hình API key và được Google cho phép.','Tùy cấu hình'),
 ('US-H01','Host tạo homestay có ảnh','Nhập tên, địa chỉ, mô tả và chọn ảnh; catalog cập nhật sau lưu.','Local/browser'),
 ('US-H02','Host quản lý phòng','Thêm/sửa phòng, giá, sức chứa, kích hoạt và trạng thái dọn/bảo trì.','Có'),
 ('US-H03','Host xử lý yêu cầu','Duyệt/từ chối đơn hợp lệ; trạng thái cập nhật ở danh sách và dashboard.','Có'),
 ('US-H04','Host theo dõi lịch','Xem ngày có khách, bảo trì và khả năng nhận phòng theo từng phòng.','Local demo'),
 ('US-H05','Host nhận/trả phòng','Xác minh payload QR demo, booking và thời điểm trước khi cập nhật trạng thái.','QR demo'),
 ('US-H06','Host quản lý thu/chi','Ghi payment/expense, lọc kỳ và xem KPI, ADR, RevPAR, công suất.','Không đối soát ngân hàng'),
 ('US-H07','Host quản lý vận hành','Tra cứu khách, nhân sự và ca; lưu thông tin trong cùng trình duyệt.','Local demo')], [1.7,4.3,7.5,3.0]),
('PHỤ LỤC F.2 Ma trận yêu cầu chức năng','Bảng F.2. Đối chiếu yêu cầu với phân hệ',
 'Mã FR dùng để truy vết yêu cầu từ đề tài tới màn hình, model hoặc test. “Chưa có” là giới hạn chủ động của bản prototype, không được hiểu là đã kiểm thử trên server.',
 ['Mã','Yêu cầu','Nơi hiện thực / bằng chứng','Kết quả'],[
 ('FR-01','Landing giới thiệu và điều hướng khám phá','landing_page.dart; landing_page_test.dart','Có'),
 ('FR-02','Home khách có gợi ý và mở Explore','home_page.dart; home_page_test.dart','Có'),
 ('FR-03','Tìm kiếm, sắp xếp và lọc catalog','explore_page.dart; widget_test.dart','Có'),
 ('FR-04','Chi tiết homestay, phòng, gallery','detail_page.dart; gallery_test.dart','Có'),
 ('FR-05','Đăng ký/đăng nhập Guest và Host','demo_auth_repository.dart; auth_registration_flow_test.dart','Demo local'),
 ('FR-06','Không cho khách chưa đăng nhập gửi đặt','booking_form_page.dart; auth flow test','Có'),
 ('FR-07','Khôi phục route booking sau đăng nhập','go_router redirect; auth_registration_flow_test.dart','Có'),
 ('FR-08','Kiểm tra ngày, đêm, sức chứa, chồng lấn','demo_booking_repository.dart; booking_repository_test.dart','Có'),
 ('FR-09','Giá, giảm thành viên và HHL10','Booking, booking form; booking_repository_test.dart','Demo local'),
 ('FR-10','Lưu booking, lịch sử và trạng thái','demo_storage.dart; catalog_storage_test.dart','Cùng browser'),
 ('FR-11','Hủy và hết hạn giải phóng lịch','booking_repository_test.dart','Có'),
 ('FR-12','Chuyển trạng thái duyệt/check-in/out','booking_repository_test.dart; admin_operations_flow_test.dart','Có'),
 ('FR-13','Review sau check-out và một review/đơn','review.dart; review_test.dart','Có'),
 ('FR-14','CRUD homestay/phòng kèm ảnh','catalog_editor.dart; catalog_storage_test.dart','Local'),
 ('FR-15','Lịch phòng, dọn phòng, bảo trì','calendar_page.dart; housekeeping_page.dart','Local'),
 ('FR-16','Ghi payment, chi phí và tổng hợp tài chính','finance_page.dart; finance_metrics_test.dart','Demo'),
 ('FR-17','Quản lý nhân sự và ca làm','staff_page.dart; staff_management_flow_test.dart','Local'),
 ('FR-18','Tra cứu danh sách khách theo booking','guest_directory_page.dart; guest_directory_test.dart','Local'),
 ('FR-19','AI tư vấn local và Gemini tùy cấu hình','local_stay_assistant.dart; ai_service_test.dart','Tùy key/quota'),
 ('FR-20','Đồng bộ nhiều thiết bị bằng backend','Không có server/realtime trong bản hiện tại','Chưa có'),
 ('FR-21','Thanh toán online/đối soát giao dịch','Không có payment gateway','Chưa có'),
 ('FR-22','Phân quyền production và nhật ký audit server','Vai trò hiện tại chỉ là demo client','Chưa có')], [1.5,5.2,7.0,2.8]),
('PHỤ LỤC F.3 Tác nhân, quyền và mối quan hệ','Bảng F.3. Vai trò và ranh giới tác vụ',
 'Mã nguồn có AppUserRole gồm guest và host; giao diện phân hệ host hiển thị các tác vụ quản trị. Vì không có role admin độc lập hoặc máy chủ xác thực, bảng này mô tả vai trò prototype chứ không xác nhận quyền production.',
 ['Tác nhân','Được thao tác','Ràng buộc nghiệp vụ','Ngoài phạm vi bảo mật'],[
 ('Guest đã đăng nhập','Yêu thích, đặt, xem đơn, hủy theo điều kiện, review sau lưu trú','Booking gắn guestId; review yêu cầu checkedOut; không vượt sức chứa.','Local identity có thể bị chỉnh sửa ngoài app.'),
 ('Khách chưa đăng nhập','Xem landing/Explore/detail và đăng ký/đăng nhập','Gửi đặt chuyển về login và giữ route dự định.','Không gọi được booking create từ UI.'),
 ('Host','Quản lý homestay/phòng, lịch, đơn, thanh toán demo, chi phí, ca','Thao tác ghi yêu cầu actorId sở hữu homestay; booking theo hostId.','Không có server-side role validation.'),
 ('Gemini API','Nhận yêu cầu sinh nội dung khi key cấu hình','Tác vụ online có timeout/error/quota; local assistant không gọi mạng.','API key Flutter Web có thể bị trích xuất.'),
 ('Browser storage','Lưu tài khoản, catalog, booking, review, staff, favorite','Nằm trên origin/trình duyệt; cùng máy mới có dữ liệu.','Không backup/đồng bộ cross-device.'),
 ('Ứng dụng Flutter','Điều hướng, hiển thị, validate ở client','Riverpod cập nhật view; go_router bảo vệ route UI.','Client validation không thay thế backend.')], [2.7,5.3,5.1,3.4]),
('PHỤ LỤC F.4 Từ điển dữ liệu','Bảng F.4. Trường dữ liệu trong các model chính',
 'Từ điển dưới đây lấy từ serialization model hiện tại. Kiểu được ghi ở mức khái niệm; JSON được lưu ở SharedPreferences, chưa phải schema Firestore hay hợp đồng API.',
 ['Thực thể','Trường','Kiểu','Ý nghĩa'],[
 ('AppUser','uid, email, displayName','String','Định danh local, email và tên hiển thị.'),('AppUser','role, createdAt','enum, DateTime','guest/host và thời điểm tạo tài khoản.'),
 ('Homestay','id, hostId','String','Mã nơi nghỉ và người vận hành demo.'),('Homestay','name, city, address','String','Tên, thành phố và địa chỉ.'),('Homestay','description, amenities','String, List<String>','Mô tả và tiện nghi khai báo.'),('Homestay','imageUrls, color','List<String>, int','Ảnh chọn/asset tham chiếu và màu UI.'),
 ('Room','id, homestayId','String','Mã phòng và homestay cha.'),('Room','name, price, capacity','String, int, int','Tên phòng, giá đêm và sức chứa.'),('Room','active','bool','Phòng có được mở nhận đặt hay không.'),('Room','housekeepingStatus','enum','ready, needsCleaning, cleaning, maintenance.'),
 ('Booking','id, roomId, homestayId','String','Đơn và phòng/nơi nghỉ được đặt.'),('Booking','hostId, guestId','String','Hai bên trong booking demo.'),('Booking','guestName, guestPhone','String','Thông tin khách chụp tại lúc tạo đơn.'),('Booking','roomName','String','Tên phòng được lưu cùng đơn.'),('Booking','checkIn, checkOut','DateTime','Khoảng lưu trú; ngày trả là biên không chiếm phòng.'),('Booking','guests, pricePerNight','int','Số người và giá được dùng để tính đơn.'),('Booking','memberDiscountPercent','int','Mức giảm thành viên trong demo.'),('Booking','couponDiscountPercent, couponCode','int, String','Mức giảm và mã đã áp dụng.'),('Booking','createdAt, expiresAt','DateTime','Thời điểm tạo và hạn đơn chờ.'),('Booking','status, note','enum, String','Trạng thái vòng đời và ghi chú.'),('Booking','payments','List<PaymentRecord>','Các lần thanh toán ghi nhận trong demo.'),
 ('PaymentRecord','id, amount, method','String, int, String','Mã, số tiền và phương thức.'),('PaymentRecord','paidAt, note','DateTime, String','Thời điểm và ghi chú giao dịch.'),
 ('StayReview','bookingId, homestayId','String','Review gắn duy nhất booking và homestay.'),('StayReview','guestId, guestName','String','Khách đã ở.'),('StayReview','rating, comment, createdAt','int, String, DateTime','Điểm, nội dung và thời gian.'),
 ('FinanceEntry','id, title, category','String','Khoản thu/chi và phân loại.'),('FinanceEntry','amount, date, status','int, DateTime, enum','Số tiền VND, ngày và paid/pending.'),('FinanceEntry','note','String','Ghi chú nội bộ.'),
 ('StaffMember','id, name, role','String','Hồ sơ nhân viên trong module vận hành.'),('StaffShift','id, staffId, start, end','String, DateTime','Ca được liên kết nhân viên.')], [2.6,4.0,3.0,6.9]),
('PHỤ LỤC F.5 Vòng đời booking và ngày ở','Bảng F.5. Chuyển trạng thái và quy tắc giữ phòng',
 'Hàm overlaps dùng quy tắc khoảng nửa mở [checkIn, checkOut): phòng trả ngày nào có thể nhận khách mới từ chính ngày đó. Pending hết hạn được tính là expired khi đọc theo thời điểm hiện tại.',
 ['Trạng thái nguồn','Sự kiện','Trạng thái đích','Điều kiện/hiệu ứng'],[
 ('pending','Host duyệt','confirmed','Đơn còn hiệu lực, cùng homestay và còn khả năng nhận.'),('pending','Host từ chối','rejected','Không nhận; giải phóng khoảng ngày.'),('pending','Khách hủy','cancelled','Chủ đơn thao tác; phòng có thể được đặt lại.'),('pending','Qua expiresAt','expired','Không thể duyệt đơn cũ; không còn chặn lịch.'),('confirmed','Đến ngày nhận; xác minh QR','checkedIn','Mã phải khớp booking; phòng sẵn sàng.'),('confirmed','Khách hủy đủ điều kiện','cancelled','Đối chiếu thời hạn 24 giờ trước ngày đến.'),('checkedIn','Hoàn thành lưu trú','checkedOut','Ngày checkout hợp lệ; phòng chuyển needsCleaning.'),('checkedOut','Khách gửi review','checkedOut + review','Review gắn guest và booking; chỉ một review/đơn.'),('rejected/cancelled/expired','Yêu cầu nhận phòng','Không đổi','Trạng thái cuối; không mở check-in.'),('Bất kỳ đơn đang giữ phòng','Tạo đơn cùng phòng/ngày trùng','Từ chối tạo','Từ chối nếu overlaps và trạng thái còn blocks(now).')], [3.3,3.5,3.3,6.4]),
('PHỤ LỤC F.6 Chỉ số tài chính và công thức','Bảng F.6. Phân biệt giá trị đơn, tiền thu và chỉ số phòng',
 'Báo cáo tài chính đọc booking và expense local. Tiền đã thu là cash flow; doanh thu lưu trú được phân bổ theo số đêm thực ở. Hai khái niệm không được cộng hoặc gắn nhãn thay cho nhau.',
 ['Chỉ số','Công thức / nguồn','Diễn giải','Giới hạn'],[
 ('Giá trị đơn','price × nights − discount','Tổng theo báo giá của booking.','Không đồng nghĩa đã thu tiền.'),('Đã thanh toán','Σ PaymentRecord.amount','Các khoản thu đã nhập cho đơn.','Không có xác nhận từ ngân hàng.'),('Còn phải thu','max(total − paidAmount, 0)','Phần còn lại theo sổ local.','Có thể chênh sổ thật.'),('Chi phí','Σ FinanceEntry.amount theo kỳ/trạng thái','Khoản vận hành đã ghi.','Người dùng tự nhập.'),('Net revenue','revenue − expenses','Kết quả tổng hợp của trang finance.','Phải xác định rõ basis doanh thu.'),('Room nights','Số ngày giao giữa kỳ và lưu trú thực','Ngày bảo trì không coi là có khách.','Dựa trạng thái checkedIn/checkedOut.'),('Occupancy','room nights ÷ available room nights','Tỷ lệ lấp đầy phòng khả dụng.','Không tính room-night bảo trì.'),('ADR','stay revenue ÷ room nights','Doanh thu lưu trú bình quân/đêm.','0 nếu không có đêm ở.'),('RevPAR','stay revenue ÷ available room nights','Doanh thu trên phòng khả dụng.','Chỉ có ý nghĩa khi mẫu số > 0.'),('Revenue by stay month','Cắt khoảng [checkIn, checkOut) theo tháng','Đếm phần đêm ở trong tháng báo cáo.','Đơn checkedIn giới hạn tới hôm nay UTC+7.')], [3.0,5.0,4.8,3.7]),
('PHỤ LỤC F.7 Ma trận kiểm thử hồi quy','Bảng F.7. Kịch bản và tệp kiểm thử liên quan',
 'Các test là kiểm thử tự động unit/widget ở isolate Flutter. Bảng ghi đường dẫn bằng tên tệp; kết quả tổng số lần chạy được cập nhật trong Phụ lục B sau khi chạy bộ test cuối cùng.',
 ['Nhóm','Kịch bản','Tệp kiểm thử','Mức kiểm chứng'],[
 ('Điều hướng','Admin không thấy Explore; logout về landing','admin_navigation_logout_test.dart','Widget'),('Auth','Đăng ký guest/host, login và restore route booking','auth_registration_flow_test.dart','Widget'),('Auth','Tài khoản/session tồn tại sau reload','catalog_storage_test.dart','Storage integration'),('Booking','Giảm thành viên và HHL10 được lưu','booking_repository_test.dart','Repository'),('Booking','Ngày sai, trùng lịch, bảo trì và sức chứa','booking_repository_test.dart','Repository'),('Booking','Pending hết hạn giải phóng phòng','booking_repository_test.dart','Repository'),('Booking','Hủy, duyệt, check-in/out theo vòng đời','booking_repository_test.dart','Repository'),('Booking','Không check-in trước ngày hoặc sau ngày trả','booking_repository_test.dart','Repository'),('Booking','Booking và lịch sử tách theo user','catalog_storage_test.dart','Storage integration'),('Catalog','CRUD có sở hữu, validation và ảnh','catalog_storage_test.dart','Repository'),('Catalog','Ảnh homestay còn sau serialize/deserialize','catalog_storage_test.dart','Model'),('Review','Chỉ guest của đơn checkedOut được review một lần','review_test.dart','Repository'),('Finance','ADR/RevPAR dùng doanh thu lưu trú','finance_metrics_test.dart','Unit'),('Finance','Dashboard giải thích 7 tháng và biểu đồ','admin_operations_flow_test.dart','Widget'),('Finance','Thêm expense hoạt động','admin_operations_flow_test.dart','Widget'),('Operations','Cập nhật trạng thái dọn phòng','admin_operations_flow_test.dart','Widget'),('Operations','Shift liên kết profile nhân viên','staff_management_flow_test.dart','Widget'),('Guest data','Danh sách khách khớp tên tài khoản','guest_directory_test.dart','Widget'),('Home','Home mở Explore; host bị chuyển khỏi Home khách','home_page_test.dart','Widget'),('Explore','Sắp giá, lọc, mở chi tiết','widget_test.dart','Widget'),('Image','14 điểm đến × 3 ảnh không trùng','gallery_test.dart','Unit'),('Image','42 asset ảnh đọc được từ bundle','gallery_test.dart','Asset bundle'),('AI local','Trợ lý không bịa điểm chưa có trong catalog','local_stay_assistant_test.dart','Unit'),('AI online','Timeout, key sai, 403, 429 được giải thích','ai_service_test.dart','Mock HTTP'),('AI UI','403 Gemini vẫn cho dùng gợi ý local','ai_widget_test.dart','Widget'),('Profile','Hồ sơ/role switch không tràn ở 320px','widget_test.dart','Responsive widget')], [2.2,6.0,4.8,3.5]),
('PHỤ LỤC F.8 Quy trình thao tác demo','Bảng F.8. Luồng sử dụng dành cho khách và host',
 'Các bước được viết cho bản demo chạy trên cùng trình duyệt. Việc mở tab ẩn danh hoặc browser khác tạo một vùng lưu trữ riêng; không dùng tài khoản giả làm dữ liệu thật.',
 ['Vai trò','Bước','Thao tác','Kết quả mong đợi'],[
 ('Guest','1','Mở landing rồi chọn Khám phá.','Hiện điểm đến và catalog mẫu.'),('Guest','2','Tìm theo địa điểm; thử lọc và sắp xếp.','Danh sách thay đổi theo điều kiện.'),('Guest','3','Mở homestay, xem phòng và gallery.','Có giá, sức chứa, tiện nghi và chú thích ảnh.'),('Guest','4','Chọn Đặt phòng khi chưa có phiên.','Chuyển login và lưu route quay lại.'),('Guest','5','Đăng ký hoặc đăng nhập tài khoản Guest.','Trở lại bước đặt đang chọn.'),('Guest','6','Chọn ngày, số người và mã HHL10 nếu muốn.','Tổng giá hiển thị trước khi xác nhận.'),('Guest','7','Xác nhận gửi yêu cầu.','Mã đơn/booking xuất hiện trong đơn của tôi.'),('Guest','8','Mở mục Đơn đặt, xem trạng thái.','Hiển thị pending/confirmed hoặc trạng thái hiện tại.'),('Guest','9','Sau checkout trong luồng demo, gửi review.','Review gắn với booking và hiện ở homestay.'),('Host','1','Đăng nhập qua lối vào Chủ nhà/Admin.','Mở phân hệ quản lý host.'),('Host','2','Tạo homestay, thêm ảnh và lưu.','Homestay mới xuất hiện trong catalog local.'),('Host','3','Thêm phòng với giá và sức chứa.','Phòng hiển thị để khách đặt.'),('Host','4','Mở lịch và bật trạng thái bảo trì khi cần.','Phòng bảo trì không nhận booking chồng ngày.'),('Host','5','Mở danh sách đơn và duyệt/từ chối.','Booking đổi trạng thái theo điều kiện.'),('Host','6','Dùng QR demo cho check-in/out.','Cập nhật trạng thái và housekeeping.'),('Host','7','Nhập khoản thu/chi và xem kỳ báo cáo.','KPI được tính từ dữ liệu local.'),('Host','8','Mở khách/nhân sự/ca để tra cứu.','Danh sách đọc từ cùng browser storage.')], [2.0,1.0,6.8,6.7]),
('PHỤ LỤC F.9 Ranh giới và rủi ro còn lại','Bảng F.9. Điều không nên suy diễn từ prototype',
 'Bảng này dùng khi bảo vệ để phân biệt chức năng mô phỏng với cam kết dịch vụ thật. Các hàng “chưa có” cần được chuyển thành kế hoạch khi phát triển backend.',
 ['Chủ đề','Hiện trạng kiểm chứng','Rủi ro nếu đưa vào vận hành','Bước cần có'],[
 ('Tài khoản','Local demo; mật khẩu băm và session nằm trong browser storage.','Có thể mất khi xóa dữ liệu trình duyệt; không có xác minh server.','Auth provider, reset/recovery, session revoke.'),('Phân quyền','UI/router phân nhánh guest/host.','Người sửa client có thể bỏ qua route guard.','Role claims + server authorization.'),('Booking concurrency','Repository kiểm tra overlap trong một máy.','Hai thiết bị không chia sẻ lock.','Transaction server và idempotency.'),('Lưu trữ','SharedPreferences theo origin.','Không có backup hay sync cross-device.','Database + migration + backup.'),('Thanh toán','PaymentRecord nhập thủ công.','Không có xác nhận ngân hàng/refund.','Payment gateway/webhook và ledger audit.'),('Ảnh','42 ảnh được bundle; 41 là ảnh tham khảo.','Có thể gây hiểu nhầm rằng ảnh thuộc đúng căn.','Ảnh đã xác minh và quy trình kiểm duyệt.'),('AI','Gemini gọi từ Web khi có key; có local fallback giới hạn.','Key client có thể bị trích xuất; quota/403.','Backend proxy, rate limit, redact data.'),('QR','Payload nội bộ để demo nhận phòng.','Không chống chụp lại hoặc giả lập ở production.','Token ký, expiry, one-time server validation.'),('Báo cáo tiền','Tính từ dữ liệu do user demo nhập.','Không là sổ kế toán đã đối soát.','Ledger bất biến, phân quyền và kiểm toán.'),('Thông báo','Không có dịch vụ push làm nguồn dữ liệu.','Không bảo đảm giao thông báo.','FCM + inbox phía server.')], [2.6,4.6,5.0,4.3])
]
for args in tables: add_matrix(*args)

shots=[('01-home.jpg','Trang Home'),('02-explore.jpg','Trang Khám phá'),('03-detail.jpg','Chi tiết homestay'),('04-booking.jpg','Form đặt phòng'),('05-bookings.jpg','Lịch sử đặt phòng khách'),('06-favorites.jpg','Danh sách yêu thích'),('07-login.jpg','Đăng nhập khách'),('08-register.jpg','Đăng ký tài khoản'),('09-profile.jpg','Hồ sơ khách'),('10-admin-dashboard.jpg','Tổng quan quản trị'),('11-admin-finance.jpg','Quản lý tài chính'),('12-admin-calendar.jpg','Lịch phòng'),('13-admin-housekeeping.jpg','Quản lý buồng phòng'),('14-ai-assistant.jpg','Trợ lý AI offline')]
D.add_page_break()
for i in range(0,14,2):
 D.add_heading(f'PHỤ LỤC G. ẢNH CHỤP GIAO DIỆN {i+1:02d}–{i+2:02d}',level=1)
 for file,label in shots[i:i+2]:
  fp=AS/file
  if fp.exists():
   p=D.add_paragraph(); p.alignment=WD_ALIGN_PARAGRAPH.CENTER; p.add_run().add_picture(str(fp),width=Cm(14.2))
   p=D.add_paragraph(label+' — localhost:8083'); p.alignment=WD_ALIGN_PARAGRAPH.CENTER
 if i < 12: D.add_page_break()
out=OUT/'Bao_cao_do_an_HHL_Stay.docx'; D.save(out); print('DOCX',out,'content sections',len(P),'verify exported page count after rendering')

import '../../homestay/domain/catalog.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';
import '../../review/domain/review.dart';

class DemoBookingRepository implements BookingRepository {
  DemoBookingRepository({DateTime Function()? clock, bool seed = true})
    : _clock = clock ?? DateTime.now {
    if (seed) {
      final today = vietnamToday(now);
      _bookings.add(
        Booking(
          id: 'HHL-0001',
          roomId: 'pine-1',
          homestayId: 'pine',
          hostId: 'host-demo',
          guestId: 'other-guest',
          guestName: 'Khách mẫu',
          roomName: 'Phòng thông xanh',
          checkIn: today.add(const Duration(days: 2)),
          checkOut: today.add(const Duration(days: 4)),
          guests: 2,
          pricePerNight: 650000,
          createdAt: now,
          expiresAt: now,
          status: BookingStatus.confirmed,
        ),
      );
      _sequence = 1;
    }
  }
  final DateTime Function() _clock;
  final List<Booking> _bookings = [];
  final List<StayReview> _reviews = [];
  @override
  List<StayReview> get reviews => List.unmodifiable(_reviews);
  int _sequence = 0;
  @override
  DateTime get now => _clock();
  @override
  List<Booking> get bookings => List.unmodifiable(_bookings);
  @override
  List<Homestay> get homestays => List.unmodifiable(_homestays);
  final List<Homestay> _homestays = [
    Homestay(
      id: 'pine',
      hostId: 'host-demo',
      name: 'Nhà Bên Đồi',
      city: 'Đà Lạt',
      address: 'Khu Trại Mát, Đà Lạt',
      color: 0xFF2F6757,
      description:
          'Một căn nhà nhỏ giữa sắc xanh của đồi thông. Không gian yên tĩnh, '
          'có ban công và khu bếp chung cho những ngày nghỉ chậm rãi.',
      amenities: ['Wi-Fi', 'Bếp', 'Bãi đỗ xe'],
    ),
    Homestay(
      id: 'sea',
      hostId: 'host-demo',
      name: 'Hiên Nhà Biển',
      city: 'Đà Nẵng',
      address: 'Khu Mỹ An, Đà Nẵng',
      color: 0xFF356A85,
      description:
          'Không gian sáng thoáng với tông màu biển. Phù hợp cho cặp đôi '
          'hoặc nhóm bạn muốn nghỉ ngơi và khám phá thành phố.',
      amenities: ['Wi-Fi', 'Điều hòa', 'Bãi đỗ xe'],
    ),
    Homestay(
      id: 'garden',
      hostId: 'host-demo',
      name: 'Vườn Nắng',
      city: 'Hội An',
      address: 'Khu Cẩm Thanh, Hội An',
      color: 0xFF95603B,
      description:
          'Căn nhà bên vườn với sân chung nhiều nắng, phòng gia đình rộng '
          'và góc bếp cho những bữa cơm cùng nhau.',
      amenities: ['Wi-Fi', 'Bếp', 'Hồ bơi'],
    ),
    Homestay(
      id: 'hanoi',
      hostId: 'host-demo',
      name: 'Mây Phố Cổ',
      city: 'Hà Nội',
      address: 'Khu Hàng Bông, Hoàn Kiếm',
      color: 0xFF806047,
      description:
          'Căn hộ nhỏ giữa phố cổ, thuận tiện dạo hồ và khám phá những con ngõ Hà Nội.',
      amenities: ['Wi-Fi', 'Điều hòa', 'Bếp'],
    ),
    Homestay(
      id: 'sapa',
      hostId: 'host-demo',
      name: 'Hiên Mây Sa Pa',
      city: 'Sa Pa',
      address: 'Khu Tả Van, Sa Pa',
      color: 0xFF416B64,
      description:
          'Không gian nghỉ dưỡng nhìn ra núi, phù hợp cho những ngày chậm rãi giữa mây trời.',
      amenities: ['Wi-Fi', 'Bếp', 'Bãi đỗ xe'],
    ),
    Homestay(
      id: 'ninhbinh',
      hostId: 'host-demo',
      name: 'Nhà Bên Núi',
      city: 'Ninh Bình',
      address: 'Khu Tràng An, Ninh Bình',
      color: 0xFF5F7448,
      description:
          'Góc ở yên tĩnh giữa thiên nhiên, thuận tiện khám phá Tràng An và những cung đường đạp xe.',
      amenities: ['Wi-Fi', 'Bãi đỗ xe', 'Hồ bơi'],
    ),
    Homestay(
      id: 'halong',
      hostId: 'host-demo',
      name: 'Gió Vịnh',
      city: 'Hạ Long',
      address: 'Khu Bãi Cháy, Hạ Long',
      color: 0xFF426D82,
      description:
          'Điểm dừng chân thoáng đãng cho chuyến đi biển cùng bạn bè và gia đình.',
      amenities: ['Wi-Fi', 'Điều hòa', 'Bãi đỗ xe'],
    ),
    Homestay(
      id: 'hue',
      hostId: 'host-demo',
      name: 'Nắng Bên Sông',
      city: 'Huế',
      address: 'Khu Vỹ Dạ, Huế',
      color: 0xFF926F51,
      description:
          'Nơi ở nhẹ nhàng để khám phá ẩm thực và nhịp sống bên dòng Hương.',
      amenities: ['Wi-Fi', 'Bếp', 'Điều hòa'],
    ),
    Homestay(
      id: 'nhatrang',
      hostId: 'host-demo',
      name: 'Sóng Xanh',
      city: 'Nha Trang',
      address: 'Khu Lộc Thọ, Nha Trang',
      color: 0xFF327E96,
      description:
          'Căn hộ sáng thoáng cho kỳ nghỉ biển, có đủ tiện nghi cho nhóm nhỏ.',
      amenities: ['Wi-Fi', 'Điều hòa', 'Hồ bơi'],
    ),
    Homestay(
      id: 'quynhon',
      hostId: 'host-demo',
      name: 'Nhà Của Gió',
      city: 'Quy Nhơn',
      address: 'Khu Ghềnh Ráng, Quy Nhơn',
      color: 0xFF45828C,
      description:
          'Không gian nghỉ gần biển với góc sinh hoạt chung cho chuyến đi cùng bạn bè.',
      amenities: ['Wi-Fi', 'Bếp', 'Bãi đỗ xe'],
    ),
    Homestay(
      id: 'phuquoc',
      hostId: 'host-demo',
      name: 'Mùa Biển Đảo',
      city: 'Phú Quốc',
      address: 'Khu Dương Đông, Phú Quốc',
      color: 0xFF418D8D,
      description:
          'Chốn nghỉ nhiều ánh sáng, phù hợp cho kỳ nghỉ biển dài ngày.',
      amenities: ['Wi-Fi', 'Điều hòa', 'Hồ bơi'],
    ),
    Homestay(
      id: 'vungtau',
      hostId: 'host-demo',
      name: 'Góc Biển Cuối Tuần',
      city: 'Vũng Tàu',
      address: 'Khu Thắng Tam, Vũng Tàu',
      color: 0xFF587C9B,
      description:
          'Căn hộ nghỉ cuối tuần gọn gàng, thuận tiện dạo biển và ăn uống.',
      amenities: ['Wi-Fi', 'Điều hòa', 'Bếp'],
    ),
    Homestay(
      id: 'cantho',
      hostId: 'host-demo',
      name: 'Miệt Vườn An Nhiên',
      city: 'Cần Thơ',
      address: 'Khu Cái Răng, Cần Thơ',
      color: 0xFF608460,
      description: 'Một góc xanh để nghỉ ngơi và khám phá nhịp sống miền Tây.',
      amenities: ['Wi-Fi', 'Bếp', 'Bãi đỗ xe'],
    ),
    Homestay(
      id: 'saigon',
      hostId: 'host-demo',
      name: 'Ban Công Sài Gòn',
      city: 'TP. Hồ Chí Minh',
      address: 'Khu Bến Nghé, Quận 1',
      color: 0xFF9C6558,
      description:
          'Căn hộ giữa trung tâm với chỗ làm việc và bếp nhỏ cho kỳ nghỉ linh hoạt.',
      amenities: ['Wi-Fi', 'Bếp', 'Điều hòa'],
    ),
  ];
  @override
  List<Room> get rooms => List.unmodifiable(_rooms);
  final List<Room> _rooms = [
    Room(
      id: 'pine-1',
      homestayId: 'pine',
      name: 'Phòng thông xanh',
      price: 650000,
      capacity: 2,
    ),
    Room(
      id: 'pine-2',
      homestayId: 'pine',
      name: 'Phòng gác mái',
      price: 950000,
      capacity: 4,
    ),
    Room(
      id: 'sea-1',
      homestayId: 'sea',
      name: 'Phòng ban công',
      price: 800000,
      capacity: 2,
    ),
    Room(
      id: 'sea-2',
      homestayId: 'sea',
      name: 'Phòng gia đình',
      price: 1200000,
      capacity: 5,
    ),
    Room(
      id: 'garden-1',
      homestayId: 'garden',
      name: 'Phòng nhìn ra vườn',
      price: 750000,
      capacity: 3,
    ),
    Room(
      id: 'garden-2',
      homestayId: 'garden',
      name: 'Phòng sân sau',
      price: 600000,
      capacity: 2,
      active: false,
    ),
    Room(
      id: 'hanoi-1',
      homestayId: 'hanoi',
      name: 'Phòng phố cổ',
      price: 720000,
      capacity: 2,
    ),
    Room(
      id: 'sapa-1',
      homestayId: 'sapa',
      name: 'Phòng hướng núi',
      price: 680000,
      capacity: 2,
    ),
    Room(
      id: 'sapa-2',
      homestayId: 'sapa',
      name: 'Phòng gia đình',
      price: 1100000,
      capacity: 4,
    ),
    Room(
      id: 'ninhbinh-1',
      homestayId: 'ninhbinh',
      name: 'Phòng bên vườn',
      price: 780000,
      capacity: 3,
    ),
    Room(
      id: 'halong-1',
      homestayId: 'halong',
      name: 'Phòng nghỉ hướng vịnh',
      price: 1050000,
      capacity: 2,
    ),
    Room(
      id: 'hue-1',
      homestayId: 'hue',
      name: 'Phòng nắng sớm',
      price: 560000,
      capacity: 2,
    ),
    Room(
      id: 'nhatrang-1',
      homestayId: 'nhatrang',
      name: 'Phòng nghỉ ven biển',
      price: 880000,
      capacity: 2,
    ),
    Room(
      id: 'quynhon-1',
      homestayId: 'quynhon',
      name: 'Phòng cho nhóm bạn',
      price: 820000,
      capacity: 4,
    ),
    Room(
      id: 'phuquoc-1',
      homestayId: 'phuquoc',
      name: 'Phòng nghỉ đảo',
      price: 1250000,
      capacity: 3,
    ),
    Room(
      id: 'vungtau-1',
      homestayId: 'vungtau',
      name: 'Phòng cuối tuần',
      price: 690000,
      capacity: 2,
    ),
    Room(
      id: 'cantho-1',
      homestayId: 'cantho',
      name: 'Phòng miệt vườn',
      price: 590000,
      capacity: 3,
    ),
    Room(
      id: 'saigon-1',
      homestayId: 'saigon',
      name: 'Studio trung tâm',
      price: 980000,
      capacity: 2,
    ),
  ];

  Map<String, dynamic> toJson() => {
    'version': 2,
    'sequence': _sequence,
    'homestays': homestays.map((h) => h.toJson()).toList(),
    'rooms': rooms.map((r) => r.toJson()).toList(),
    'bookings': bookings.map((b) => b.toJson()).toList(),
    'reviews': reviews.map((r) => r.toJson()).toList(),
  };
  factory DemoBookingRepository.fromJson(
    Map<String, dynamic> j, {
    DateTime Function()? clock,
  }) {
    if (j['version'] != 1 && j['version'] != 2)
      throw const FormatException('Unsupported demo version');
    final repo = DemoBookingRepository(seed: false, clock: clock);
    final addedHomes = repo._homestays
        .where((h) => !{'pine', 'sea', 'garden'}.contains(h.id))
        .toList();
    final addedRooms = repo._rooms
        .where((r) => !{'pine', 'sea', 'garden'}.contains(r.homestayId))
        .toList();
    repo._homestays
      ..clear()
      ..addAll(
        (j['homestays'] as List).map(
          (h) => Homestay.fromJson(Map<String, dynamic>.from(h)),
        ),
      );
    repo._rooms
      ..clear()
      ..addAll(
        (j['rooms'] as List).map(
          (r) => Room.fromJson(Map<String, dynamic>.from(r)),
        ),
      );
    repo._bookings.addAll(
      (j['bookings'] as List).map(
        (b) => Booking.fromJson(Map<String, dynamic>.from(b)),
      ),
    );
    repo._reviews.addAll(
      (j['reviews'] as List? ?? const []).map(
        (r) => StayReview.fromJson(Map<String, dynamic>.from(r)),
      ),
    );
    repo._sequence = j['sequence'] as int;
    if (j['version'] == 1) {
      final homeIds = repo._homestays.map((h) => h.id).toSet();
      repo._homestays.addAll(addedHomes.where((h) => !homeIds.contains(h.id)));
      final roomIds = repo._rooms.map((r) => r.id).toSet();
      repo._rooms.addAll(
        addedRooms.where(
          (r) =>
              !roomIds.contains(r.id) &&
              repo._homestays.any((h) => h.id == r.homestayId),
        ),
      );
    }
    return repo;
  }

  // Called by DemoStorage only, so repository unit tests and production
  // booking flows do not acquire synthetic history implicitly.
  void ensureRevenueDemoBookings() {
    final existingIds = _bookings.map((booking) => booking.id).toSet();
    final aprilIn = DateTime.utc(2026, 4, 14);
    final aprilOut = DateTime.utc(2026, 4, 16);
    final mayIn = DateTime.utc(2026, 5, 12);
    final mayOut = DateTime.utc(2026, 5, 14);
    final samples = [
      Booking(
        id: 'HHL-DEMO-2026-04',
        roomId: 'pine-1',
        homestayId: 'pine',
        hostId: 'host-demo',
        guestId: 'demo-analytics',
        guestName: 'Dữ liệu demo tháng 4',
        roomName: 'Phòng thông xanh',
        checkIn: aprilIn,
        checkOut: aprilOut,
        guests: 2,
        pricePerNight: 650000,
        createdAt: aprilIn.subtract(const Duration(days: 5)),
        expiresAt: aprilIn.subtract(const Duration(days: 4)),
        status: BookingStatus.checkedOut,
        note: 'Đơn demo lịch sử để kiểm tra biểu đồ doanh thu tháng 4.',
      ),
      Booking(
        id: 'HHL-DEMO-2026-05',
        roomId: 'garden-1',
        homestayId: 'garden',
        hostId: 'host-demo',
        guestId: 'demo-analytics',
        guestName: 'Dữ liệu demo tháng 5',
        roomName: 'Phòng nhìn ra vườn',
        checkIn: mayIn,
        checkOut: mayOut,
        guests: 2,
        pricePerNight: 750000,
        createdAt: mayIn.subtract(const Duration(days: 5)),
        expiresAt: mayIn.subtract(const Duration(days: 4)),
        status: BookingStatus.checkedOut,
        note: 'Đơn demo lịch sử để kiểm tra biểu đồ doanh thu tháng 5.',
      ),
      Booking(
        id: 'HHL-DEMO-2026-06',
        roomId: 'sea-1',
        homestayId: 'sea',
        hostId: 'host-demo',
        guestId: 'demo-analytics',
        guestName: 'Dữ liệu demo tháng 6',
        roomName: 'Phòng ban công',
        checkIn: DateTime.utc(2026, 6, 10),
        checkOut: DateTime.utc(2026, 6, 12),
        guests: 2,
        pricePerNight: 800000,
        createdAt: DateTime.utc(2026, 6, 5),
        expiresAt: DateTime.utc(2026, 6, 6),
        status: BookingStatus.checkedOut,
        note: 'Đơn demo lịch sử để kiểm tra biểu đồ doanh thu tháng 6.',
      ),
      Booking(
        id: 'HHL-DEMO-2026-07',
        roomId: 'hanoi-1',
        homestayId: 'hanoi',
        hostId: 'host-demo',
        guestId: 'demo-analytics',
        guestName: 'Dữ liệu demo tháng 7',
        roomName: 'Phòng phố cổ',
        checkIn: DateTime.utc(2026, 7, 10),
        checkOut: DateTime.utc(2026, 7, 11),
        guests: 2,
        pricePerNight: 720000,
        createdAt: DateTime.utc(2026, 7, 5),
        expiresAt: DateTime.utc(2026, 7, 6),
        status: BookingStatus.checkedOut,
        note: 'Đơn demo lịch sử để kiểm tra biểu đồ doanh thu tháng 7.',
      ),
      Booking(
        id: 'HHL-DEMO-2026-08',
        roomId: 'sapa-1',
        homestayId: 'sapa',
        hostId: 'host-demo',
        guestId: 'demo-analytics',
        guestName: 'Dữ liệu demo tháng 8',
        roomName: 'Phòng hướng núi',
        checkIn: DateTime.utc(2026, 8, 10),
        checkOut: DateTime.utc(2026, 8, 12),
        guests: 2,
        pricePerNight: 680000,
        createdAt: DateTime.utc(2026, 8, 5),
        expiresAt: DateTime.utc(2026, 8, 6),
        status: BookingStatus.checkedOut,
        note: 'Đơn demo lịch sử để kiểm tra biểu đồ doanh thu tháng 8.',
      ),
      Booking(
        id: 'HHL-DEMO-2026-09',
        roomId: 'saigon-1',
        homestayId: 'saigon',
        hostId: 'host-demo',
        guestId: 'demo-analytics',
        guestName: 'Dữ liệu demo tháng 9',
        roomName: 'Studio trung tâm',
        checkIn: DateTime.utc(2026, 9, 10),
        checkOut: DateTime.utc(2026, 9, 11),
        guests: 2,
        pricePerNight: 980000,
        createdAt: DateTime.utc(2026, 9, 5),
        expiresAt: DateTime.utc(2026, 9, 6),
        status: BookingStatus.checkedOut,
        note: 'Đơn demo lịch sử để kiểm tra biểu đồ doanh thu tháng 9.',
      ),
    ];
    _bookings.addAll(samples.where((booking) => !existingIds.contains(booking.id)));
  }
  void _owner(String homeId, String actorId) {
    if (!_homestays.any((h) => h.id == homeId && h.hostId == actorId)) {
      throw const BookingException('Bạn không có quyền quản lý homestay này.');
    }
  }

  @override
  void saveHomestay(Homestay home, {required String actorId}) {
    final index = _homestays.indexWhere((h) => h.id == home.id);
    if (actorId != 'host-demo' || home.hostId != actorId)
      throw const BookingException('Không có quyền quản lý.');
    if (index >= 0) _owner(home.id, actorId);
    if ([
          home.id,
          home.name,
          home.city,
          home.address,
          home.description,
        ].any((v) => v.trim().isEmpty) ||
        home.name.length > 100 ||
        home.city.length > 100 ||
        home.address.length > 300 ||
        home.description.length > 2000) {
      throw const BookingException('Nhập đủ thông tin hợp lệ của homestay.');
    }
    if (index < 0) {
      _homestays.add(home);
    } else {
      _homestays[index] = home;
    }
  }

  bool _hasOpenBooking(String roomId) =>
      _bookings.any((b) => b.roomId == roomId && b.blocks(now));
  @override
  void saveRoom(Room room, {required String actorId}) {
    _owner(room.homestayId, actorId);
    final index = _rooms.indexWhere((r) => r.id == room.id);
    if (index >= 0 && _rooms[index].homestayId != room.homestayId)
      throw const BookingException(
        'Không thể chuyển phòng sang homestay khác.',
      );
    if (room.id.trim().isEmpty ||
        room.name.trim().isEmpty ||
        room.name.length > 100 ||
        room.price < 10000 ||
        room.price > 100000000 ||
        room.capacity < 1 ||
        room.capacity > 30) {
      throw const BookingException(
        'Tên phòng bắt buộc; giá 10.000–100.000.000đ, sức chứa 1–30 khách.',
      );
    }
    if (!room.active && _hasOpenBooking(room.id))
      throw const BookingException(
        'Phòng còn đơn chờ, đã xác nhận hoặc đang lưu trú. Xử lý đơn trước khi bảo trì.',
      );
    if (index < 0) {
      _rooms.add(room);
    } else {
      _rooms[index] = room;
    }
  }

  @override
  void deleteRoom(String id, {required String actorId}) {
    final room = _rooms.where((r) => r.id == id).firstOrNull;
    if (room == null) throw const BookingException('Phòng không tồn tại.');
    _owner(room.homestayId, actorId);
    if (_hasOpenBooking(id))
      throw const BookingException('Không thể xóa phòng còn đơn cần xử lý.');
    _rooms.removeWhere((r) => r.id == id);
  }

  @override
  void deleteHomestay(String id, {required String actorId}) {
    _owner(id, actorId);
    if (_rooms.any((r) => r.homestayId == id))
      throw const BookingException('Hãy xóa các phòng trước khi xóa homestay.');
    _homestays.removeWhere((h) => h.id == id);
  }

  @override
  bool available(Room room, DateTime checkIn, DateTime checkOut) =>
      room.active &&
      !_bookings.any(
        (b) =>
            b.roomId == room.id &&
            b.blocks(now) &&
            overlaps(
              stayDate(checkIn),
              stayDate(checkOut),
              b.checkIn,
              b.checkOut,
            ),
      );

  @override
  Booking create({
    required String roomId,
    required String guestId,
    required String guestName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    String note = '',
  }) {
    final candidates = rooms.where((r) => r.id == roomId);
    if (candidates.isEmpty)
      throw const BookingException('Phòng không tồn tại.');
    final room = candidates.single;
    final start = stayDate(checkIn), end = stayDate(checkOut);
    final nights = end.difference(start).inDays;
    if (guestId.trim().isEmpty || guestName.trim().isEmpty) {
      throw const BookingException('Vui lòng nhập tên khách.');
    }
    if (guestName.trim().length > 100 || note.trim().length > 500) {
      throw const BookingException(
        'Tên tối đa 100 ký tự, ghi chú tối đa 500 ký tự.',
      );
    }
    if (start.isBefore(vietnamToday(now)))
      throw const BookingException('Không thể đặt ngày đã qua.');
    if (nights < 1 || nights > 30)
      throw const BookingException('Thời gian ở phải từ 1 đến 30 đêm.');
    if (guests < 1 || guests > room.capacity)
      throw const BookingException('Số khách vượt sức chứa hoặc không hợp lệ.');
    if (!available(room, start, end))
      throw const BookingException(
        'Phòng đang bảo trì hoặc đã có đơn trong thời gian này.',
      );
    final home = homestays.singleWhere((h) => h.id == room.homestayId);
    // Synchronous in one isolate only. Firebase needs server-side transactions.
    final booking = Booking(
      id: 'HHL-${(++_sequence).toString().padLeft(4, '0')}',
      roomId: room.id,
      homestayId: home.id,
      hostId: home.hostId,
      guestId: guestId,
      guestName: guestName.trim(),
      roomName: room.name,
      checkIn: start,
      checkOut: end,
      guests: guests,
      pricePerNight: room.price,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      note: note.trim(),
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  void transition(String id, BookingStatus target, {required String actorId}) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index < 0) throw const BookingException('Không tìm thấy đơn.');
    final booking = _bookings[index];
    final status = booking.effectiveStatus(now);
    final isGuest = actorId == booking.guestId;
    final isHost = actorId == booking.hostId;
    final allowed =
        (isGuest &&
            status == BookingStatus.pending &&
            target == BookingStatus.cancelled) ||
        (isHost &&
            ((status == BookingStatus.pending &&
                    {
                      BookingStatus.confirmed,
                      BookingStatus.rejected,
                    }.contains(target)) ||
                (status == BookingStatus.confirmed &&
                    target == BookingStatus.checkedIn) ||
                (status == BookingStatus.checkedIn &&
                    target == BookingStatus.checkedOut)));
    if (!allowed)
      throw const BookingException(
        'Không có quyền hoặc trạng thái đơn không cho phép thao tác này.',
      );
    final today = vietnamToday(now);
    if (target == BookingStatus.confirmed &&
        !today.isBefore(booking.checkOut)) {
      throw const BookingException('Khoảng lưu trú đã kết thúc.');
    }
    if (target == BookingStatus.checkedIn &&
        (today.isBefore(booking.checkIn) ||
            !today.isBefore(booking.checkOut))) {
      throw const BookingException('Chỉ nhận phòng trong khoảng ngày lưu trú.');
    }
    _bookings[index] = booking.withStatus(target);
  }

  @override
  StayReview addReview(
    String bookingId, {
    required String actorId,
    required int rating,
    required String comment,
  }) {
    final booking = _bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null ||
        booking.guestId != actorId ||
        booking.effectiveStatus(now) != BookingStatus.checkedOut) {
      throw const BookingException(
        'Chỉ khách đã trả phòng mới được đánh giá đơn này.',
      );
    }
    if (_reviews.any((r) => r.bookingId == bookingId)) {
      throw const BookingException('Đơn này đã được đánh giá.');
    }
    final cleanComment = comment.trim();
    if (rating < 1 ||
        rating > 5 ||
        cleanComment.isEmpty ||
        cleanComment.length > 500) {
      throw const BookingException(
        'Chọn 1–5 sao và viết nhận xét tối đa 500 ký tự.',
      );
    }
    final review = StayReview(
      bookingId: bookingId,
      homestayId: booking.homestayId,
      guestId: actorId,
      guestName: booking.guestName,
      rating: rating,
      comment: cleanComment,
      createdAt: now,
    );
    _reviews.add(review);
    return review;
  }
}

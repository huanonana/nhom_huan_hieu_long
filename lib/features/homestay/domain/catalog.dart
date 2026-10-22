class Homestay {
  Map<String, dynamic> toJson() => {
    'id': id,
    'hostId': hostId,
    'name': name,
    'city': city,
    'address': address,
    'description': description,
    'amenities': amenities,
    'color': color,
    'imageUrls': imageUrls,
  };
  factory Homestay.fromJson(Map<String, dynamic> j) => Homestay(
    id: j['id'] as String,
    hostId: j['hostId'] as String,
    name: j['name'] as String,
    city: j['city'] as String,
    address: j['address'] as String,
    description: j['description'] as String,
    amenities: List<String>.from(j['amenities'] as List),
    color: j['color'] as int,
    imageUrls: List<String>.from(j['imageUrls'] as List? ?? const []),
  );

  const Homestay({
    required this.id,
    required this.hostId,
    required this.name,
    required this.city,
    required this.address,
    required this.description,
    required this.amenities,
    required this.color,
    this.imageUrls = const [],
  });
  final String id, hostId, name, city, address, description;
  final List<String> amenities;
  final List<String> imageUrls;
  final int color;
}

enum HousekeepingStatus { ready, needsCleaning, cleaning, maintenance }

extension HousekeepingStatusLabel on HousekeepingStatus {
  String get label => switch (this) {
    HousekeepingStatus.ready => 'Sẵn sàng',
    HousekeepingStatus.needsCleaning => 'Cần dọn',
    HousekeepingStatus.cleaning => 'Đang dọn',
    HousekeepingStatus.maintenance => 'Bảo trì',
  };
}

class Room {
  Map<String, dynamic> toJson() => {
    'id': id,
    'homestayId': homestayId,
    'name': name,
    'price': price,
    'capacity': capacity,
    'active': active,
    'housekeepingStatus': housekeepingStatus.name,
  };
  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'] as String,
    homestayId: j['homestayId'] as String,
    name: j['name'] as String,
    price: j['price'] as int,
    capacity: j['capacity'] as int,
    active: j['active'] as bool,
    housekeepingStatus: HousekeepingStatus.values.firstWhere(
      (status) => status.name == j['housekeepingStatus'],
      orElse: () => HousekeepingStatus.ready,
    ),
  );

  const Room({
    required this.id,
    required this.homestayId,
    required this.name,
    required this.price,
    required this.capacity,
    this.active = true,
    this.housekeepingStatus = HousekeepingStatus.ready,
  });
  final String id, homestayId, name;
  final int price, capacity;
  final bool active;
  final HousekeepingStatus housekeepingStatus;

  Room withHousekeeping(HousekeepingStatus status) => Room(
    id: id,
    homestayId: homestayId,
    name: name,
    price: price,
    capacity: capacity,
    active: active,
    housekeepingStatus: status,
  );
}

class Homestay {
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'hostId': hostId,
    'name': name,
    'city': city,
    'address': address,
    'description': description,
    'amenities': amenities,
    'color': color,
  };

  factory Homestay.fromFirestore(Map<String, dynamic> data, {String? id}) =>
      Homestay(
        id: data['id'] as String? ?? id ?? '',
        hostId: data['hostId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        city: data['city'] as String? ?? '',
        address: data['address'] as String? ?? '',
        description: data['description'] as String? ?? '',
        amenities: List<String>.from(data['amenities'] as List? ?? const []),
        color: data['color'] as int? ?? 0xFF2F6757,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'hostId': hostId,
    'name': name,
    'city': city,
    'address': address,
    'description': description,
    'amenities': amenities,
    'color': color,
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
  });
  final String id, hostId, name, city, address, description;
  final List<String> amenities;
  final int color;
}

class Room {
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'homestayId': homestayId,
    'name': name,
    'price': price,
    'capacity': capacity,
    'active': active,
  };

  factory Room.fromFirestore(Map<String, dynamic> data, {String? id}) => Room(
    id: data['id'] as String? ?? id ?? '',
    homestayId: data['homestayId'] as String? ?? '',
    name: data['name'] as String? ?? '',
    price: (data['price'] as num?)?.toInt() ?? 0,
    capacity: (data['capacity'] as num?)?.toInt() ?? 1,
    active: data['active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'homestayId': homestayId,
    'name': name,
    'price': price,
    'capacity': capacity,
    'active': active,
  };
  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'] as String,
    homestayId: j['homestayId'] as String,
    name: j['name'] as String,
    price: j['price'] as int,
    capacity: j['capacity'] as int,
    active: j['active'] as bool,
  );

  const Room({
    required this.id,
    required this.homestayId,
    required this.name,
    required this.price,
    required this.capacity,
    this.active = true,
  });
  final String id, homestayId, name;
  final int price, capacity;
  final bool active;
}

import '../../homestay/domain/catalog.dart';
import '../../../core/widgets/common.dart';

/// Small, offline catalog assistant used when no Anthropic key is configured.
/// It only recommends stays and prices that exist in the current app data.
class LocalStayAssistant {
  const LocalStayAssistant._();

  static String reply({
    required String query,
    required List<Homestay> homestays,
    required List<Room> rooms,
  }) {
    if (homestays.isEmpty) {
      return 'Danh sách homestay hiện đang trống nên mình chưa thể gợi ý. '
          'Bạn thử lại sau khi chủ nhà thêm chỗ nghỉ nhé.';
    }

    final normalizedQuery = _normalize(query);
    final cityMatches = homestays.where((home) {
      final city = _normalize(home.city);
      return city.isNotEmpty && normalizedQuery.contains(city);
    }).toList();
    final candidates = cityMatches.isNotEmpty ? cityMatches : homestays;
    final withRooms = <({Homestay home, List<Room> rooms})>[];
    for (final home in candidates) {
      final activeRooms = rooms
          .where((room) => room.homestayId == home.id && room.active)
          .toList();
      if (activeRooms.isNotEmpty)
        withRooms.add((home: home, rooms: activeRooms));
    }

    if (withRooms.isEmpty) {
      if (cityMatches.isNotEmpty) {
        return 'Mình tìm thấy ${cityMatches.map((home) => home.city).toSet().join(', ')} '
            'trong danh sách, nhưng hiện chưa có phòng đang mở để hiển thị giá. '
            'Bạn có thể xem các điểm đến khác: ${_cities(homestays)}.';
      }
      return 'Mình chưa thấy phòng đang mở trong dữ liệu hiện tại. '
          'Các điểm đến đang có: ${_cities(homestays)}.';
    }

    final wantsLowPrice = RegExp(
      r'\b(re|thap|tiet kiem|budget|gia mem)\b',
    ).hasMatch(normalizedQuery);
    withRooms.sort((a, b) {
      final aPrice = a.rooms
          .map((room) => room.price)
          .reduce((x, y) => x < y ? x : y);
      final bPrice = b.rooms
          .map((room) => room.price)
          .reduce((x, y) => x < y ? x : y);
      return wantsLowPrice
          ? aPrice.compareTo(bPrice)
          : a.home.name.compareTo(b.home.name);
    });

    final heading = cityMatches.isNotEmpty
        ? 'Mình tìm được một vài lựa chọn ở ${cityMatches.first.city}:'
        : 'Mình gợi ý một vài chỗ đang có phòng trong danh sách:';
    final suggestions = withRooms
        .take(3)
        .map((entry) {
          final price = entry.rooms
              .map((room) => room.price)
              .reduce((a, b) => a < b ? a : b);
          final amenities = entry.home.amenities.take(3).toList();
          final detail = amenities.isEmpty ? '' : ' · ${amenities.join(', ')}';
          return '• ${entry.home.name} — ${entry.home.city}, từ ${money(price)}/đêm$detail';
        })
        .join('\n');

    return '$heading\n$suggestions\n\n'
        'Đây là gợi ý theo dữ liệu homestay và phòng hiện có; bạn hãy mở chi tiết '
        'để kiểm tra lịch trống và thông tin mới nhất. '
        'Claude chưa được cấu hình nên mình đang hỗ trợ offline.';
  }

  static String _cities(List<Homestay> homes) => homes
      .map((home) => home.city)
      .where((city) => city.trim().isNotEmpty)
      .toSet()
      .join(', ');

  static String _normalize(String value) {
    var result = value.toLowerCase();
    const replacements = {
      'áàảãạăắằẳẵặâấầẩẫậ': 'a',
      'éèẻẽẹêếềểễệ': 'e',
      'íìỉĩị': 'i',
      'óòỏõọôốồổỗộơớờởỡợ': 'o',
      'úùủũụưứừửữự': 'u',
      'ýỳỷỹỵ': 'y',
      'đ': 'd',
    };
    for (final entry in replacements.entries) {
      for (final character in entry.key.split('')) {
        result = result.replaceAll(character, entry.value);
      }
    }
    return result.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}

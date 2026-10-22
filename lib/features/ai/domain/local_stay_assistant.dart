import '../../homestay/domain/catalog.dart';
import '../../../core/widgets/common.dart';

/// Small, offline catalog assistant used when no Gemini key is configured.
/// It only recommends stays and prices that exist in the current app data.
class LocalStayAssistant {
  const LocalStayAssistant._();

  static String reply({
    required String query,
    required List<Homestay> homestays,
    required List<Room> rooms,
    String offlineNotice =
        'Gemini chưa được cấu hình nên mình đang hỗ trợ offline.',
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
        'để kiểm tra lịch trống và thông tin mới nhất. $offlineNotice';
  }

  static String summarizeReviews(List<String> reviewTexts) {
    if (reviewTexts.isEmpty) return 'Chưa có đánh giá để tóm tắt.';
    final ratings = <int>[];
    final comments = <({int? rating, String text})>[];
    for (final raw in reviewTexts) {
      final match = RegExp(
        r'^(\d+(?:\.\d+)?)/5 sao:\s*(.*)$',
      ).firstMatch(raw.trim());
      final rating = match == null ? null : double.tryParse(match.group(1)!);
      final comment = match?.group(2)?.trim() ?? raw.trim();
      if (rating != null) ratings.add(rating.round().clamp(1, 5));
      if (comment.isNotEmpty) {
        comments.add((rating: rating?.round(), text: comment));
      }
    }
    if (comments.isEmpty) return 'Chưa có nội dung đánh giá để tóm tắt.';
    final average = ratings.isEmpty
        ? null
        : ratings.reduce((a, b) => a + b) / ratings.length;
    final positives = comments
        .where((item) => item.rating == null || item.rating! >= 4)
        .take(2)
        .map((item) => '“${item.text}”')
        .toList();
    final improvements = comments
        .where((item) => item.rating != null && item.rating! <= 3)
        .take(2)
        .map((item) => '“${item.text}”')
        .toList();
    return [
      'Tóm tắt đánh giá theo dữ liệu hiện có (chế độ offline):',
      if (average != null)
        '• Điểm trung bình: ${average.toStringAsFixed(1)}/5 từ ${ratings.length} đánh giá.',
      if (positives.isNotEmpty) '• Đánh giá tích cực: ${positives.join('; ')}',
      if (improvements.isNotEmpty)
        '• Nội dung cần lưu ý: ${improvements.join('; ')}',
      if (ratings.isEmpty)
        '• Chưa có điểm sao có thể tổng hợp; nội dung đánh giá được giữ nguyên bên dưới.',
      'Bản tóm tắt được tạo tại thiết bị; Gemini trực tuyến hiện không khả dụng.',
    ].join('\n');
  }

  static String generateDescription(
    String homestayName,
    String city,
    List<String> amenities,
  ) {
    final name = homestayName.trim();
    final location = city.trim();
    final features = amenities
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    final locationText = location.isEmpty ? '' : ' tại $location';
    final amenityText = features.isEmpty
        ? 'Chưa có tiện nghi nào được cập nhật.'
        : 'Tiện nghi đã cập nhật: ${features.join(', ')}.';
    return '$name$locationText. $amenityText Hãy xem thông tin phòng và lịch '
        'còn trống trước khi gửi yêu cầu đặt. '
        'Mô tả gợi ý offline được tạo từ thông tin bạn đã nhập.';
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

import 'package:flutter/material.dart';

class CategoryMappingService {
  static const Map<String, String> categoryEnToVi = {
    "top": "Tin nổi bật",
    "business": "Kinh doanh",
    "sports": "Thể thao",
    "education": "Giáo dục",
    "entertainment": "Giải trí",
    "environment": "Môi trường",
    "food": "Ẩm thực",
    "health": "Sức khỏe",
    "lifestyle": "Đời sống",
    "politics": "Chính trị",
    "science": "Khoa học",
    "technology": "Công nghệ",
    "tourism": "Du lịch",
    "world": "Thế giới",
    "homepage": "Trang chủ",
    "startup": "Khởi nghiệp",
    "law": "Pháp luật",
    "current": "Thời sự",
    "digital": "Khoa học công nghệ",
    "auto": "Xe",
    "opinion": "Ý kiến",
    "confession": "Tâm sự",
    "funny": "Cười",
    "most-viewed": "Tin xem nhiều",
    "society": "Xã hội",
    "job": "Việc làm",
    "real-estate": "Bất động sản",
    "domestic": "Trong nước",
    "other": "Khác",
    "crime": "Tội phạm",
  };

  static final Map<String, List<Color>> _categoryColorMap = {
    'top': [Color(0xFFFFD600), Color(0xFFFFEB3B)],
    'business': [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    'sports': [Color(0xFFFF6F00), Color(0xFFFF9800)],
    'education': [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
    'entertainment': [Color(0xFFE91E63), Color(0xFFF06292)],
    'environment': [Color(0xFF388E3C), Color(0xFF66BB6A)],
    'food': [Color(0xFFFF5722), Color(0xFFFF7043)],
    'health': [Color(0xFF00ACC1), Color(0xFF26C6DA)],
    'lifestyle': [Color(0xFFAB47BC), Color(0xFFBA68C8)],
    'politics': [Color(0xFF5D4037), Color(0xFF8D6E63)],
    'science': [Color(0xFF303F9F), Color(0xFF3F51B5)],
    'technology': [Color(0xFF455A64), Color(0xFF607D8B)],
    'tourism': [Color(0xFF0097A7), Color(0xFF00BCD4)],
    'world': [Color(0xFF512DA8), Color(0xFF673AB7)],
    'other': [Color(0xFF616161), Color(0xFF757575)],
    'homepage': [Color(0xFF0288D1), Color(0xFFB3E5FC)],
    'startup': [Color(0xFF009688), Color(0xFF4DD0E1)],
    'law': [Color(0xFFD32F2F), Color(0xFFEF5350)],
    'current': [Color(0xFF1976D2), Color(0xFF2196F3)],
    'digital': [Color(0xFF303F9F), Color(0xFF607D8B)],
    'car': [Color(0xFF607D8B), Color(0xFF90A4AE)],
    'opinion': [Color(0xFF6D4C41), Color(0xFFBCAAA4)],
    'confession': [Color(0xFF8D6E63), Color(0xFFD7CCC8)],
    'funny': [Color(0xFFFFA000), Color(0xFFFFD54F)],
    'most-viewed': [Color(0xFF512DA8), Color(0xFF9575CD)],
    'society': [Color(0xFF388E3C), Color(0xFFA5D6A7)],
    'job': [Color(0xFF8BC34A), Color(0xFFC5E1A5)],
    'real-estate': [Color(0xFF8D6E63), Color(0xFFD7CCC8)],
    'domestic': [Color(0xFF1976D2), Color(0xFFBBDEFB)],
    'crime': [Color(0xFFD32F2F), Color(0xFFFFCDD2)],
  };

  static final Map<String, IconData> _categoryIconMap = {
    'top': Icons.star,
    'business': Icons.business_center,
    'sports': Icons.sports_soccer,
    'education': Icons.school,
    'entertainment': Icons.movie,
    'environment': Icons.eco,
    'food': Icons.restaurant,
    'health': Icons.local_hospital,
    'lifestyle': Icons.style,
    'politics': Icons.account_balance,
    'science': Icons.science,
    'technology': Icons.computer,
    'tourism': Icons.flight,
    'world': Icons.public,
    'other': Icons.category,
    'homepage': Icons.home,
    'startup': Icons.rocket_launch,
    'law': Icons.gavel,
    'current': Icons.newspaper,
    'digital': Icons.memory,
    'car': Icons.directions_car,
    'opinion': Icons.forum,
    'confession': Icons.favorite,
    'funny': Icons.emoji_emotions,
    'most-viewed': Icons.trending_up,
    'society': Icons.people,
    'job': Icons.work,
    'real-estate': Icons.house,
  };

  static final Set<String> _viCategories =
      categoryEnToVi.values.map((e) => _cleanCategory(e)).toSet();

  static String _cleanCategory(String category) {
    return category
        .replaceAll(RegExp(r'[^$-\w\s\u00C0-\u1EF9-]'), '')
        .trim()
        .toLowerCase();
  }

  static String _capitalizeWords(String input) {
    if (input.isEmpty) return "";
    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '',
        )
        .join(' ');
  }

  static String categoryToVietnamese(String? en) {
    if (en == null) return "Không xác định";
    return categoryEnToVi[en] ?? en;
  }

  static String toVietnamese(dynamic category) {
    if (category == null) return "";
    String categoryStr;
    if (category is List && category.isNotEmpty) {
      categoryStr = category[0].toString();
    } else {
      categoryStr = category.toString();
    }
    if (categoryStr.isEmpty) return "";
    // Ưu tiên dùng mapping chính xác
    final vi = categoryToVietnamese(categoryStr);
    if (vi != categoryStr) return vi;
    // Nếu không match, thử làm sạch và so khớp gần đúng
    String cleanCategory = _cleanCategory(categoryStr);
    if (categoryEnToVi.containsKey(cleanCategory)) {
      return categoryEnToVi[cleanCategory]!;
    }
    // Nếu đã là tiếng Việt hoặc không cần dịch
    if (_viCategories.contains(cleanCategory)) {
      return _capitalizeWords(cleanCategory);
    }
    // So khớp gần đúng theo key
    for (var entry in categoryEnToVi.entries) {
      if (cleanCategory.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    // Fallback: viết hoa từng từ
    return _capitalizeWords(cleanCategory);
  }

  static String toEnglish(String? vi) {
    if (vi == null) return "unknown";
    if (vi.isEmpty) return "unknown";
    // Tìm kiếm ngược lại từ tiếng Việt sang tiếng Anh
    for (var entry in categoryEnToVi.entries) {
      if (entry.value.toLowerCase() == vi.toLowerCase()) {
        return entry.key;
      }
    }
    // Nếu không tìm thấy, trả về tiếng Việt đã viết hoa
    return _capitalizeWords(vi);
  }

  /// Lấy màu sắc chuẩn cho category (dùng cho UI)
  static List<Color> getCategoryColors(String? category) {
    if (category == null || category.isEmpty) {
      return [Colors.blueGrey, Colors.blueGrey.shade200];
    }
    final eng = toEnglish(category);
    if (_categoryColorMap.containsKey(eng)) {
      return _categoryColorMap[eng]!;
    }
    final vi = toVietnamese(category).toLowerCase();
    if (_categoryColorMap.containsKey(vi)) {
      return _categoryColorMap[vi]!;
    }
    return [Colors.blueGrey, Colors.blueGrey.shade200];
  }

  /// Lấy icon phù hợp cho category (dùng cho UI)
  static IconData getCategoryIcon(String? category) {
    if (category == null || category.isEmpty) return Icons.category;
    final eng = toEnglish(category);
    if (_categoryIconMap.containsKey(eng)) {
      return _categoryIconMap[eng]!;
    }
    final vi = toVietnamese(category).toLowerCase();
    if (_categoryIconMap.containsKey(vi)) {
      return _categoryIconMap[vi]!;
    }
    return Icons.category;
  }
}

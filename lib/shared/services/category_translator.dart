class CategoryMappingService {
  static Map<String, String> categoryEnToVi = {
    // API fetcher categories
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
    "other": "Khác",

    // RSS fetcher categories (VnExpress)
    "trang-chu": "Trang chủ",
    "the-gioi": "Thế giới",
    "thoi-su": "Thời sự",
    "kinh-doanh": "Kinh doanh",
    "startup": "Startup",
    "giai-tri": "Giải trí",
    "the-thao": "Thể thao",
    "phap-luat": "Pháp luật",
    "giao-duc": "Giáo dục",
    "tin-moi-nhat": "Tin mới nhất",
    "tin-noi-bat": "Tin nổi bật",
    "suc-khoe": "Sức khỏe",
    "doi-song": "Đời sống",
    "du-lich": "Du lịch",
    "so-hoa": "Khoa học công nghệ",
    "oto-xe-may": "Xe",
    "y-kien": "Ý kiến",
    "tam-su": "Tâm sự",
    "cuoi": "Cười",
    "tin-xem-nhieu": "Tin xem nhiều",

    // Selenium fetcher categories (Dantri)
    "xa-hoi": "Xã hội",
    "cong-nghe": "Công nghệ",
    "viec-lam": "Việc làm",
  };

  static String categoryToVietnamese(String? en) {
    if (en == null) return "Không xác định";
    return categoryEnToVi[en] ?? en;
  }

  /// Chuyển đổi category từ bất kỳ format nào sang Vietnamese để hiển thị
  static String toVietnamese(dynamic category) {
    if (category == null) return "";

    // Handle List<String> case
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

  static String _cleanCategory(String category) {
    return category
        .replaceAll(RegExp(r'[^\w\s\u00C0-\u1EF9-]'), '')
        .trim()
        .toLowerCase();
  }

  static String _capitalizeWords(String input) {
    if (input.isEmpty) return "";
    return input
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  static final Set<String> _viCategories = categoryEnToVi.values
      .map((e) => _cleanCategory(e))
      .toSet();
}
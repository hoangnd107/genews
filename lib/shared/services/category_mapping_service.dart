/// Service để xử lý category mapping giữa tiếng Anh và tiếng Việt
/// Hỗ trợ cả direction: EN -> VI và VI -> EN
class CategoryMappingService {
  // Map từ English sang Vietnamese
  static const Map<String, String> _enToVi = {
    'business': 'Kinh doanh',
    'crime': 'Tội phạm',
    'domestic': 'Trong nước',
    'education': 'Giáo dục',
    'entertainment': 'Giải trí',
    'environment': 'Môi trường',
    'food': 'Ẩm thực',
    'health': 'Sức khỏe',
    'lifestyle': 'Đời sống',
    'politics': 'Chính trị',
    'science': 'Khoa học',
    'sports': 'Thể thao',
    'technology': 'Công nghệ',
    'top': 'Nổi bật',
    'tourism': 'Du lịch',
    'world': 'Thế giới',
    'other': 'Khác',
  };

  // Map từ Vietnamese sang English (generated từ _enToVi)
  static final Map<String, String> _viToEn = {
    for (var entry in _enToVi.entries) entry.value: entry.key,
  };

  /// Chuyển đổi category từ bất kỳ format nào sang Vietnamese để hiển thị
  static String toVietnamese(dynamic category) {
    if (category == null) return "";

    // Handle List<String> case
    String categoryStr;
    if (category is List<String>) {
      if (category.isEmpty) return "";
      categoryStr = category[0]; // Take first category
    } else {
      categoryStr = category.toString();
    }

    if (categoryStr.isEmpty) return "";

    // Clean up category string
    String cleanCategory = _cleanCategory(categoryStr);

    // Try direct English -> Vietnamese mapping
    if (_enToVi.containsKey(cleanCategory)) {
      return _enToVi[cleanCategory]!;
    }

    // Try exact Vietnamese match (already Vietnamese)
    if (_viToEn.containsKey(cleanCategory)) {
      return cleanCategory; // Already in Vietnamese
    }

    // Try partial matching for English
    for (var entry in _enToVi.entries) {
      if (cleanCategory.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Try partial matching for Vietnamese
    for (var viCategory in _viToEn.keys) {
      if (_normalizeVietnamese(cleanCategory) ==
          _normalizeVietnamese(viCategory)) {
        return viCategory;
      }
    }

    // If no match found, return capitalized version
    return _capitalizeWords(cleanCategory);
  }

  /// Chuyển đổi category từ Vietnamese sang English (for queries)
  static String toEnglish(String vietnameseCategory) {
    if (vietnameseCategory.isEmpty) return "";

    String cleanCategory = _cleanCategory(vietnameseCategory);

    // Try direct Vietnamese -> English mapping
    if (_viToEn.containsKey(cleanCategory)) {
      return _viToEn[cleanCategory]!;
    }

    // Try normalized matching
    for (var entry in _viToEn.entries) {
      if (_normalizeVietnamese(cleanCategory) ==
          _normalizeVietnamese(entry.key)) {
        return entry.value;
      }
    }

    // If no match, return as is (might be already English)
    return cleanCategory.toLowerCase();
  }

  /// Lấy tất cả categories available (Vietnamese)
  static List<String> getAllVietnameseCategories() {
    return _enToVi.values.toList()..sort();
  }

  /// Lấy tất cả categories available (English)
  static List<String> getAllEnglishCategories() {
    return _enToVi.keys.toList()..sort();
  }

  /// Check if category exists (in either language)
  static bool isValidCategory(String category) {
    String cleanCategory = _cleanCategory(category);
    return _enToVi.containsKey(cleanCategory) ||
        _viToEn.containsKey(cleanCategory);
  }

  /// Lấy English category key để sử dụng trong queries
  static String getCategoryKey(String displayCategory) {
    return toEnglish(displayCategory);
  }

  // Helper methods

  static String _cleanCategory(String category) {
    return category
        .replaceAll(
          RegExp(r'[^\w\s\u00C0-\u1EF9]'),
          '',
        ) // Keep Vietnamese chars
        .trim()
        .toLowerCase();
  }

  static String _normalizeVietnamese(String text) {
    // Remove Vietnamese accents for comparison
    const Map<String, String> vietnameseMap = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    String normalized = text.toLowerCase();
    vietnameseMap.forEach((accented, normal) {
      normalized = normalized.replaceAll(accented, normal);
    });
    return normalized;
  }

  static String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '',
        )
        .join(' ');
  }
}

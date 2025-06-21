import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum cho các lựa chọn cỡ chữ
enum AppFontSize { small, medium, large }

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.system; // Mặc định theo hệ thống

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    if (mode == ThemeMode.light) {
      themeModeString = 'light';
    } else if (mode == ThemeMode.dark) {
      themeModeString = 'dark';
    } else {
      themeModeString = 'system'; // Mặc định là system
    }
    await prefs.setString(_themeModeKey, themeModeString);
    notifyListeners();
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Nếu bạn muốn kiểm tra theme hệ thống thực sự, bạn cần context.
      // Tuy nhiên, để đơn giản, chúng ta có thể giả định nó không phải là dark
      // hoặc bạn có thể truyền BuildContext vào đây nếu cần thiết cho Switch.
      // Cách đơn giản hơn là Switch sẽ dựa trên giá trị _themeMode trực tiếp.
      return false; // Hoặc dựa trên một giá trị mặc định nào đó
    }
    return _themeMode == ThemeMode.dark;
  }
}

class FontSizeProvider with ChangeNotifier {
  static const String _fontSizeKey = 'fontSize';
  AppFontSize _selectedFontSize = AppFontSize.medium; // Mặc định là vừa

  AppFontSize get selectedFontSize => _selectedFontSize;

  // Hệ số nhân cho cỡ chữ
  double get fontSizeMultiplier {
    switch (_selectedFontSize) {
      case AppFontSize.small:
        return 0.8;
      case AppFontSize.medium:
        return 1.0;
      case AppFontSize.large:
        return 1.2;
    }
  }

  // Ánh xạ AppFontSize thành chuỗi để hiển thị
  String get selectedFontSizeText {
    switch (_selectedFontSize) {
      case AppFontSize.small:
        return 'Nhỏ';
      case AppFontSize.medium:
        return 'Vừa';
      case AppFontSize.large:
        return 'Lớn';
    }
  }

  FontSizeProvider() {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSizeString = prefs.getString(_fontSizeKey);
    if (fontSizeString != null) {
      _selectedFontSize = AppFontSize.values.firstWhere(
            (e) => e.toString() == fontSizeString,
        orElse: () => AppFontSize.medium,
      );
    }
    notifyListeners();
  }

  Future<void> setFontSize(AppFontSize size) async {
    _selectedFontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontSizeKey, size.toString());
    notifyListeners();
  }
}
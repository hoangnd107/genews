import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:genews/features/home/presentation/providers/settings_provider.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy instance của các provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: <Widget>[
          // --- Cài đặt Chế độ Sáng/Tối ---
          ListTile(
            leading: Icon( // Thêm icon ở đây
              themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            ),
            title: const Text('Chế độ tối'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (bool value) {
                themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              },
              activeColor: Colors.white,
            ),
          ),
          const Divider(),

          // --- Cài đặt Cỡ chữ ---
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Cỡ chữ'),
            trailing: Row( // Sử dụng Row để có thể thêm cả text và icon mũi tên nếu muốn
              mainAxisSize: MainAxisSize.min, // Để Row không chiếm toàn bộ không gian
              children: <Widget>[
                Text(fontSizeProvider.selectedFontSizeText),
                const SizedBox(width: 8), // Khoảng cách nhỏ giữa text và icon
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), // Icon mũi tên nhỏ
              ],
            ),
            onTap: () { // ListTile vẫn có thể nhấn được
              _showFontSizeDialog(context, fontSizeProvider);
            },
          ),
          const Divider(),

          // Thêm các cài đặt khác ở đây nếu cần
        ],
      ),
    );
  }

  // Hộp thoại chọn cỡ chữ (giữ nguyên như trước)
  void _showFontSizeDialog(BuildContext context, FontSizeProvider fontSizeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn cỡ chữ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppFontSize.values.map((size) {
              return RadioListTile<AppFontSize>(
                title: Text(
                  _getFontSizeText(size),
                  style: TextStyle(fontSize: _getPreviewFontSize(size)),
                ),
                value: size,
                groupValue: fontSizeProvider.selectedFontSize,
                onChanged: (AppFontSize? value) {
                  if (value != null) {
                    fontSizeProvider.setFontSize(value);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getFontSizeText(AppFontSize size) {
    switch (size) {
      case AppFontSize.small:
        return 'Nhỏ';
      case AppFontSize.medium:
        return 'Vừa';
      case AppFontSize.large:
        return 'Lớn';
    }
  }

  double _getPreviewFontSize(AppFontSize size) {
    switch (size) {
      case AppFontSize.small:
        return 12.0;
      case AppFontSize.medium:
        return 16.0;
      case AppFontSize.large:
        return 20.0;
    }
  }
}
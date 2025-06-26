import 'package:flutter/material.dart';
import 'package:genews/features/bookmarks/views/bookmarks_screen.dart';
import 'package:genews/features/news/views/home_screen.dart';
import 'package:genews/features/news/views/discover_screen.dart';
import 'package:genews/features/settings/views/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    DiscoverScreen(),
    BookmarksScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bottomNavBarBackgroundColor =
        isDarkMode ? theme.colorScheme.surface : Colors.white;

    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      extendBody: false, // Đảm bảo body không extend dưới bottom navigation bar
      extendBodyBehindAppBar:
          false, // Đảm bảo body không extend phía sau app bar
      resizeToAvoidBottomInset:
          false, // Ngăn bottom nav bar bị đẩy lên khi có keyboard
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomNavBarBackgroundColor,
          border: Border(top: BorderSide(color: borderColor, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 5,
              offset: Offset(0, -2), // changes position of shadow
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: isDarkMode ? Colors.white : Colors.grey[900],
          unselectedItemColor: Colors.grey,
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.transparent,
          elevation: 0,
          enableFeedback: true, // Thêm haptic feedback khi tap
          showSelectedLabels: true, // Luôn hiển thị label của item được chọn
          showUnselectedLabels:
              true, // Luôn hiển thị label của item không được chọn
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              activeIcon: Icon(Icons.bookmark),
              label: 'Đã lưu',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Cài đặt'),
          ],
        ),
      ),
    );
  }
}

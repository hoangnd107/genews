import 'package:flutter/material.dart';
import 'package:genews/features/bookmarks/views/bookmarks_screen.dart';
import 'package:genews/features/news/views/home_screen.dart';
import 'package:genews/features/news/views/discover_screen.dart';
import 'package:genews/features/settings/views/settings_screen.dart';
import 'package:genews/features/main/providers/main_screen_provider.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    const BookmarksScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mainScreenProvider = Provider.of<MainScreenProvider>(context);
    final selectedIndex = mainScreenProvider.currentIndex;

    final navBarColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _screens),
      // SỬA ĐỔI: Sử dụng Row thay vì BottomNavigationBar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: navBarColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Căn giữa các item
          children: [
            _buildNavItem(
                Icons.home_outlined, Icons.home, 'Trang chủ', 0, selectedIndex),
            _buildNavItem(Icons.explore_outlined, Icons.explore, 'Khám phá', 1,
                selectedIndex),
            _buildNavItem(Icons.bookmark_border, Icons.bookmark, 'Đã lưu', 2,
                selectedIndex),
            _buildNavItem(
                Icons.menu_outlined, Icons.menu, 'Cài đặt', 3, selectedIndex),
          ],
        ),
      ),
    );
  }

  // SỬA ĐỔI: Widget cho từng item, sử dụng InkWell và Column
  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
    int selectedIndex,
  ) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final selectedColor = isDarkMode ? Colors.white : Colors.black87;
    final unselectedColor = isDarkMode ? Colors.grey[600]! : Colors.grey[500]!;

    return Expanded(
      child: InkWell(
        onTap: () =>
            Provider.of<MainScreenProvider>(context, listen: false)
                .setCurrentIndex(index),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                MainAxisAlignment.center, // Căn giữa theo chiều dọc
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: isSelected ? 1.25 : 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      size: 24,
                      color: isSelected ? selectedColor : unselectedColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

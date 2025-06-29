import 'package:flutter/material.dart';
import 'package:genews/features/main/providers/main_screen_provider.dart';
import 'package:provider/provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int? selectedIndex;

  const CustomBottomNavBar({super.key, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final navBarColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];

    return Container(
      margin: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: navBarColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor!, width: 1.2),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            Icons.home_outlined,
            Icons.home,
            'Trang chủ',
            0,
          ),
          _buildNavItem(
            context,
            Icons.explore_outlined,
            Icons.explore,
            'Khám phá',
            1,
          ),
          _buildNavItem(
            context,
            Icons.bookmark_border,
            Icons.bookmark,
            'Đã lưu',
            2,
          ),
          _buildNavItem(context, Icons.menu_outlined, Icons.menu, 'Cài đặt', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final selectedColor = isDarkMode ? Colors.white : Colors.black87;
    final unselectedColor = isDarkMode ? Colors.grey[600]! : Colors.grey[500]!;

    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          Provider.of<MainScreenProvider>(
            context,
            listen: false,
          ).setCurrentIndex(index);
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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

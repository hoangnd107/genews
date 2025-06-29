import 'package:flutter/material.dart';
import 'package:genews/features/bookmarks/views/bookmarks_screen.dart';
import 'package:genews/features/news/views/home_screen.dart';
import 'package:genews/features/news/views/discover_screen.dart';
import 'package:genews/features/settings/views/settings_screen.dart';
import 'package:genews/features/main/providers/main_screen_provider.dart';
import 'package:genews/shared/widgets/custom_bottom_nav_bar.dart';
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
    final mainScreenProvider = Provider.of<MainScreenProvider>(context);
    final selectedIndex = mainScreenProvider.currentIndex;

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: selectedIndex,
      ),
    );
  }
}

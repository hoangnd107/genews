import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Handle search functionality
              // You can show search dialog or navigate to search screen
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {
              // Handle notification tap
              // You can navigate to a notifications screen here
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Nơi tìm kiếm, xem các chủ đề thịnh hành và khám phá nguồn tin.'),
      ),
    );
  }
}
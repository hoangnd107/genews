import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá'),
      ),
      body: const Center(
        child: Text('Nơi tìm kiếm, xem các chủ đề thịnh hành và khám phá nguồn tin.'),
      ),
    );
  }
}
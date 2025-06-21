import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: const Center(
        child: Text('Quản lý tài khoản, cài đặt ứng dụng và các sở thích.'),
      ),
    );
  }
}
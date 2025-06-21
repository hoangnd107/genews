import 'package:flutter/material.dart';
import 'package:genews/features/home/presentation/providers/news_provider.dart';
import 'package:genews/features/home/presentation/views/main_screen.dart';
import 'package:offline_first_support/offline_first.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await OfflineFirst.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => NewsProvider())],
      child: MaterialApp(home: MainScreen()),
    );
  }
}

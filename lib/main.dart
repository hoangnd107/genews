import 'package:flutter/material.dart';
import 'package:genews/features/news/providers/news_provider.dart';
import 'package:genews/features/settings/providers/settings_provider.dart';
import 'package:genews/app/app.dart';
import 'package:offline_first_support/offline_first.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:genews/app/config/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await OfflineFirst.init();
  await initializeDateFormatting('vi_VN', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NewsProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FontSizeProvider()),
      ],
      child: const GeNewsApp(),
    ),
  );
}

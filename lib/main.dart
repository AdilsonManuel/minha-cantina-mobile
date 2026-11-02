import 'package:flutter/material.dart';
import 'ui/core/app_theme.dart';
import 'ui/main_navigation_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MinhaCantinaApp());
}

class MinhaCantinaApp extends StatelessWidget {
  const MinhaCantinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha Cantina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationView(),
    );
  }
}

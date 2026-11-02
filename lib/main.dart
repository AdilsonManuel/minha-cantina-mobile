import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'ui/core/app_theme.dart';
import 'ui/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('pt_BR', null);
  } catch (_) {
    // Continua caso a inicialização de locale falhe em ambientes restritos
  }
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/router.dart';
import 'config/theme.dart';

Future<void> bootstrap({required String envFile}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: envFile);
  await initializeDateFormatting('id_ID');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: InovasiOnlineApp()));
}

Future<void> main() async {
  await bootstrap(envFile: '.env');
}

class InovasiOnlineApp extends StatelessWidget {
  const InovasiOnlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Inovasi Online',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}

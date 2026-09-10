import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/router.dart';
import 'config/theme.dart';
import 'firebase_options.dart';
import 'services/push_notification_handler.dart';

Future<void> bootstrap({required String envFile}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: envFile);
  await initializeDateFormatting('id_ID');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final container = ProviderContainer();
  await PushNotificationHandler(container).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const InovasiOnlineApp(),
    ),
  );
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

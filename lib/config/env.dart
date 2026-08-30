import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api/v1';

  static String get appBaseUrl => dotenv.env['APP_BASE_URL'] ?? 'http://10.0.2.2:8000';

  static String? get googleServerClientId => dotenv.env['GOOGLE_SERVER_CLIENT_ID'];
}

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app.dart';
import 'session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.init();
  final session = SessionController(api);
  await session.loadThemeMode();
  runApp(MenuApp(session: session));
  session.bootstrap();
}

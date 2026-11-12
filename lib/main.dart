import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_controller.dart';
import 'core/key_value_storage.dart';

/// Точка входа игры «Тактика».
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppController app = await AppController.load(createPlatformStorage());
  runApp(TaktikaApp(app: app));
}

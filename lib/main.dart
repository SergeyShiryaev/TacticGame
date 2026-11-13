import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/app.dart';
import 'app/app_controller.dart';
import 'core/key_value_storage.dart';

/// Точка входа игры «Тактика».
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
  
  final AppController app = await AppController.load(createPlatformStorage());
  
  // Удаляем splash после загрузки
  FlutterNativeSplash.remove();
  
  runApp(TaktikaApp(app: app));
}

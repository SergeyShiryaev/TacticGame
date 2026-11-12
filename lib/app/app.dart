import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/menu/menu_screen.dart';
import '../l10n/app_strings.dart';
import '../ui/theme.dart';
import 'app_controller.dart';

/// Корень приложения: тема, локаль из настроек, главное меню.
class TaktikaApp extends StatelessWidget {
  const TaktikaApp({super.key, required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app.settings,
      builder: (BuildContext context, Widget? child) {
        final String? code = app.settings.languageCode;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (BuildContext ctx) => AppStrings.of(ctx).appName,
          theme: AppPalette.theme(),
          locale: code == null ? null : Locale(code),
          supportedLocales: AppStrings.supportedLocales,
          localeResolutionCallback:
              (Locale? locale, Iterable<Locale> supported) =>
                  locale?.languageCode == 'ru'
                      ? const Locale('ru')
                      : const Locale('en'),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MenuScreen(app: app),
        );
      },
    );
  }
}

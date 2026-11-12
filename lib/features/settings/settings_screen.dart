import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../ui/theme.dart';
import 'settings_controller.dart';

/// Экран настроек: язык, вибрация, звук, меньше анимаций.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsTitle),
        backgroundColor: AppPalette.background,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, Widget? child) {
            final List<(String?, String)> languages = <(String?, String)>[
              (null, s.languageSystem),
              ('ru', s.languageRu),
              ('en', s.languageEn),
            ];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    s.languageLabel,
                    style: const TextStyle(
                      color: AppPalette.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final (String? code, String label) in languages)
                  Card(
                    color: AppPalette.surface,
                    child: ListTile(
                      title: Text(label),
                      selected: controller.languageCode == code,
                      selectedColor: AppPalette.accent,
                      trailing: controller.languageCode == code
                          ? const Icon(Icons.check, color: AppPalette.accent)
                          : null,
                      onTap: () => controller.setLanguage(code),
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  color: AppPalette.surface,
                  child: SwitchListTile(
                    title: Text(s.hapticsLabel),
                    value: controller.haptics,
                    onChanged: controller.setHaptics,
                  ),
                ),
                Card(
                  color: AppPalette.surface,
                  child: SwitchListTile(
                    title: Text(s.soundLabel),
                    value: controller.sound,
                    onChanged: controller.setSound,
                  ),
                ),
                Card(
                  color: AppPalette.surface,
                  child: SwitchListTile(
                    title: Text(s.reduceMotionLabel),
                    subtitle: Text(s.reduceMotionHint),
                    value: controller.reduceMotion,
                    onChanged: controller.setReduceMotion,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../ui/theme.dart';
import 'stats_controller.dart';

/// Экран статистики.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.controller});

  final StatsController controller;

  Future<void> _reset(BuildContext context) async {
    final AppStrings s = AppStrings.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(s.statsReset),
        content: Text(s.statsResetBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.statsTitle),
        backgroundColor: AppPalette.background,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, Widget? child) {
            final GameStats st = controller.stats;
            if (st.played == 0) {
              return Center(
                child: Text(
                  s.statsEmpty,
                  style: const TextStyle(color: AppPalette.textSoft),
                ),
              );
            }
            final List<(String, String)> rows = <(String, String)>[
              (s.statsPlayed, '${st.played}'),
              (s.statsWins, '${st.wins}'),
              (s.statsPerfect, '${st.perfectWins}'),
              (s.statsBest, '${st.bestPegsLeft ?? '-'}'),
              (s.statsStreak, '${st.streak}'),
              (s.statsBestStreak, '${st.bestStreak}'),
            ];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                for (final (String label, String value) in rows)
                  Card(
                    color: AppPalette.surface,
                    child: ListTile(
                      title: Text(label),
                      trailing: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.accent,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _reset(context),
                  child: Text(s.statsReset),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

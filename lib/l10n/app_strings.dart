import 'package:flutter/widgets.dart';

/// Строки интерфейса. Язык по умолчанию — язык системы (RU или EN).
/// Добавить язык = добавить подкласс и зарегистрировать его в [forLocale].
abstract class AppStrings {
  const AppStrings();

  static const AppStrings ru = _RuStrings();
  static const AppStrings en = _EnStrings();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? ru;

  static AppStrings forLocale(Locale locale) =>
      locale.languageCode == 'en' ? en : ru;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('en'),
  ];

  String get appName;
  String get tagline;
  String get pegCountLabel;
  String get moves;
  String get undo;
  String get redo;
  String get restart;
  String get hint;
  String get help;
  String get movesHint;
  String get howToTitle;
  String get howToBody;
  String get howToClose;
  String get gameOverTitle;
  String get playAgain;
  String get close;
  String get backToMenu;
  String get share;
  String get copied;
  String get resultPerfectWin;
  String get resultLonePeg;
  String get resultGood;
  String get resultDeadEnd;
  String get menuContinue;
  String get menuNewGame;
  String get menuStats;
  String get menuSettings;
  String continueInfo(int pegs, int moves);
  String get restartConfirmTitle;
  String get restartConfirmBody;
  String get cancel;
  String get confirm;
  String get hintSearching;
  String get hintWinning;
  String get hintNoSolution;
  String get hintUnknown;
  String get statsTitle;
  String get statsPlayed;
  String get statsWins;
  String get statsPerfect;
  String get statsBest;
  String get statsStreak;
  String get statsBestStreak;
  String get statsEmpty;
  String get statsReset;
  String get statsResetBody;
  String get settingsTitle;
  String get languageLabel;
  String get languageSystem;
  String get languageRu;
  String get languageEn;
  String get hapticsLabel;
  String get soundLabel;
  String get reduceMotionLabel;
  String get reduceMotionHint;
  String shareText(int pegs, int moves);
  String semBoard(int pegs);
  String semPeg(int row, int col);
  String semEmpty(int row, int col);
}

class _RuStrings extends AppStrings {
  const _RuStrings();

  @override
  String get appName => 'Тактика';
  @override
  String get tagline => 'Головоломка на 33 ячейки';
  @override
  String get pegCountLabel => 'фишек осталось';
  @override
  String get moves => 'Ходов';
  @override
  String get undo => 'Назад';
  @override
  String get redo => 'Вперёд';
  @override
  String get restart => 'Заново';
  @override
  String get hint => 'Подсказка';
  @override
  String get help => 'Правила';
  @override
  String get movesHint =>
      'Прыгайте через фишку на пустую клетку — по вертикали или горизонтали';
  @override
  String get howToTitle => 'Как играть';
  @override
  String get howToBody =>
      'Ход — прыжок фишки через соседнюю фишку на пустую клетку за ней: '
      'только вертикально или горизонтально, диагонали запрещены. '
      'Фишка, через которую прыгнули, снимается с поля.\n\n'
      'Управление: тап по фишке (подсветка доступных ходов) и тап по целевой клетке, '
      'или перетаскивание фишки. На клавиатуре: стрелки и Enter.\n\n'
      'Цель — оставить как можно меньше фишек. Одна фишка точно в центре — '
      'идеальная победа.';
  @override
  String get howToClose => 'Понятно';
  @override
  String get gameOverTitle => 'Ходов больше нет';
  @override
  String get playAgain => 'Новая игра';
  @override
  String get close => 'Закрыть';
  @override
  String get backToMenu => 'В меню';
  @override
  String get share => 'Скопировать результат';
  @override
  String get copied => 'Скопировано';
  @override
  String get resultPerfectWin => 'Идеальная победа! Вы гроссмейстер тактики!';
  @override
  String get resultLonePeg =>
      'Отличный результат! Попробуйте привести фишку в центр.';
  @override
  String get resultGood => 'Хороший результат, но можно лучше.';
  @override
  String get resultDeadEnd => 'Тупик. Попробуйте ещё раз!';
  @override
  String get menuContinue => 'Продолжить';
  @override
  String get menuNewGame => 'Новая игра';
  @override
  String get menuStats => 'Статистика';
  @override
  String get menuSettings => 'Настройки';
  @override
  String continueInfo(int pegs, int moves) =>
      'Фишек: $pegs  •  Ходов: $moves';
  @override
  String get restartConfirmTitle => 'Начать заново?';
  @override
  String get restartConfirmBody => 'Текущая партия будет потеряна.';
  @override
  String get cancel => 'Отмена';
  @override
  String get confirm => 'Да';
  @override
  String get hintSearching => 'Ищу ход…';
  @override
  String get hintWinning => 'Этот ход сохраняет путь к победе.';
  @override
  String get hintNoSolution =>
      'Из этой позиции победить уже нельзя. Лучший результат — меньше фишек.';
  @override
  String get hintUnknown =>
      'Точного решения найти не удалось; показан возможный ход.';
  @override
  String get statsTitle => 'Статистика';
  @override
  String get statsPlayed => 'Сыграно партий';
  @override
  String get statsWins => 'Побед (1 фишка)';
  @override
  String get statsPerfect => 'Идеальных побед';
  @override
  String get statsBest => 'Лучший результат (фишек)';
  @override
  String get statsStreak => 'Текущая серия побед';
  @override
  String get statsBestStreak => 'Лучшая серия побед';
  @override
  String get statsEmpty => 'Пока нет завершённых партий';
  @override
  String get statsReset => 'Сбросить статистику';
  @override
  String get statsResetBody => 'Вся статистика будет удалена.';
  @override
  String get settingsTitle => 'Настройки';
  @override
  String get languageLabel => 'Язык';
  @override
  String get languageSystem => 'Как в системе';
  @override
  String get languageRu => 'Русский';
  @override
  String get languageEn => 'English';
  @override
  String get hapticsLabel => 'Вибрация';
  @override
  String get soundLabel => 'Звук';
  @override
  String get reduceMotionLabel => 'Меньше анимаций';
  @override
  String get reduceMotionHint => 'Фишки перемещаются без перелёта';
  @override
  String shareText(int pegs, int moves) => pegs == 1
      ? 'Тактика: победа! 1 фишка за $moves ходов.'
      : 'Тактика: осталось фишек — $pegs, ходов — $moves.';
  @override
  String semBoard(int pegs) => 'Игровое поле, фишек: $pegs';
  @override
  String semPeg(int row, int col) => 'Фишка, строка $row, столбец $col';
  @override
  String semEmpty(int row, int col) => 'Пусто, строка $row, столбец $col';
}

class _EnStrings extends AppStrings {
  const _EnStrings();

  @override
  String get appName => 'Tactics';
  @override
  String get tagline => 'Peg solitaire on 33 cells';
  @override
  String get pegCountLabel => 'pegs left';
  @override
  String get moves => 'Moves';
  @override
  String get undo => 'Undo';
  @override
  String get redo => 'Redo';
  @override
  String get restart => 'Restart';
  @override
  String get hint => 'Hint';
  @override
  String get help => 'Rules';
  @override
  String get movesHint =>
      'Jump over a peg into the empty cell — vertically or horizontally only';
  @override
  String get howToTitle => 'How to play';
  @override
  String get howToBody =>
      'A move is a jump of one peg over an adjacent peg into the empty cell '
      'behind it: vertically or horizontally, never diagonally. '
      'The jumped-over peg is removed from the board.\n\n'
      'Controls: tap a peg (legal jumps light up) and tap the target cell, '
      'or drag a peg. On a keyboard: arrow keys and Enter.\n\n'
      'Goal — leave as few pegs as possible. One peg exactly in the center '
      'is a perfect win.';
  @override
  String get howToClose => 'Got it';
  @override
  String get gameOverTitle => 'No moves left';
  @override
  String get playAgain => 'New game';
  @override
  String get close => 'Close';
  @override
  String get backToMenu => 'Menu';
  @override
  String get share => 'Copy result';
  @override
  String get copied => 'Copied';
  @override
  String get resultPerfectWin => 'Perfect win! You are a tactics grandmaster!';
  @override
  String get resultLonePeg => 'Excellent! Now try to bring that peg to the center.';
  @override
  String get resultGood => 'Good result, but you can do better.';
  @override
  String get resultDeadEnd => 'Dead end. Try again!';
  @override
  String get menuContinue => 'Continue';
  @override
  String get menuNewGame => 'New game';
  @override
  String get menuStats => 'Statistics';
  @override
  String get menuSettings => 'Settings';
  @override
  String continueInfo(int pegs, int moves) => 'Pegs: $pegs  •  Moves: $moves';
  @override
  String get restartConfirmTitle => 'Start over?';
  @override
  String get restartConfirmBody => 'The current game will be lost.';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Yes';
  @override
  String get hintSearching => 'Searching…';
  @override
  String get hintWinning => 'This move keeps a winning path open.';
  @override
  String get hintNoSolution =>
      'A win is no longer possible from here. Aim for fewer pegs.';
  @override
  String get hintUnknown =>
      'No exact solution found in time; showing a possible move.';
  @override
  String get statsTitle => 'Statistics';
  @override
  String get statsPlayed => 'Games played';
  @override
  String get statsWins => 'Wins (1 peg)';
  @override
  String get statsPerfect => 'Perfect wins';
  @override
  String get statsBest => 'Best result (pegs)';
  @override
  String get statsStreak => 'Current win streak';
  @override
  String get statsBestStreak => 'Best win streak';
  @override
  String get statsEmpty => 'No finished games yet';
  @override
  String get statsReset => 'Reset statistics';
  @override
  String get statsResetBody => 'All statistics will be deleted.';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get languageLabel => 'Language';
  @override
  String get languageSystem => 'System default';
  @override
  String get languageRu => 'Русский';
  @override
  String get languageEn => 'English';
  @override
  String get hapticsLabel => 'Haptics';
  @override
  String get soundLabel => 'Sound';
  @override
  String get reduceMotionLabel => 'Reduce motion';
  @override
  String get reduceMotionHint => 'Pegs move without flight animation';
  @override
  String shareText(int pegs, int moves) => pegs == 1
      ? 'Tactics: win! 1 peg in $moves moves.'
      : 'Tactics: $pegs pegs left in $moves moves.';
  @override
  String semBoard(int pegs) => 'Game board, $pegs pegs';
  @override
  String semPeg(int row, int col) => 'Peg, row $row, column $col';
  @override
  String semEmpty(int row, int col) => 'Empty, row $row, column $col';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings.forLocale(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

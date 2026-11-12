# Taktika (Тактика)

Peg solitaire on the classic 33-hole cross board — Flutter, no third-party packages.
Пасьянс «Тактика» на классическом поле из 33 ячеек. Только Flutter SDK, без сторонних пакетов.

**Rules / Правила.** Jump a peg over a neighbouring peg into the empty cell behind it
(vertical or horizontal only); the jumped peg is removed. Leave as few pegs as possible —
a single peg in the centre is a perfect win.
Фишка прыгает через соседнюю на пустую клетку за ней (только по вертикали и горизонтали),
побитая фишка снимается. Цель — оставить одну фишку, лучше всего в центре.

## Features

- Tap or drag to move, keyboard control (arrows, Enter, Esc) and screen-reader labels
- Undo / redo, restart, solver-based hints
- Auto-saved game: continue where you left off
- Statistics: games, wins, perfect wins, best result, win streaks
- Settings: language (system / Русский / English), haptics, sound, reduced motion
- Portrait and landscape layouts; Android, iOS and web

## Run

```sh
flutter pub get
flutter run            # pick a device
flutter test
flutter analyze
flutter build web
flutter build apk --release
```

Requires the Flutter stable channel (Dart 3.9+).

## Project layout

```
lib/
  app/        app shell: MaterialApp, AppController (settings, stats, autosave)
  core/       key-value storage (localStorage / platform channel / memory), feedback
  domain/     pure game logic: board, moves, store, solver
  features/   game, menu, settings, stats screens
  l10n/       strings (ru, en)
  ui/         theme, painters, shared widgets
test/         domain, persistence and widget tests
```

Saved data goes through a tiny `taktika/storage` platform channel (SharedPreferences on
Android, UserDefaults on iOS) and `localStorage` on the web, so no pub packages are needed.

## Release signing (Android)

1. Create a keystore: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Copy `android/key.properties.example` to `android/key.properties` and fill it in.
3. `flutter build appbundle --release`

`key.properties` and keystores are git-ignored. Without `key.properties`, release builds are
signed with the debug key so `flutter run --release` still works.

The application id is `app.taktika.game` (Android `applicationId`, iOS bundle id) — change it
in `android/app/build.gradle.kts` and `ios/Runner.xcodeproj/project.pbxproj` before publishing
to a store.

## License

No license has been chosen yet. Add a `LICENSE` file before accepting contributions.

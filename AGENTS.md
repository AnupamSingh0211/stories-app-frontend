## Cursor Cloud specific instructions

This repository is the Flutter client (`boopi_app`, branded Dharma Stories / Boopi). The audiobook backend and CMS are not in this repo. The client reads them from `.env`:

- `BACKEND_BASE_URL` is the HTTP API for stories, CMS app config, auth, profiles, favorites, and history. Set it to the VPS origin (no trailing slash) when that API is hosted elsewhere.
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` are required at startup for auth and storage. Placeholder values are enough to boot `lib/main_story_preview.dart`.
- `.env` is gitignored and listed as a Flutter asset in `pubspec.yaml`. Copy `.env.example` to `.env` before `flutter run`. `flutter test` does not need that file; tests call `dotenv.testLoad`.

Flutter is installed at `/opt/flutter` (stable 3.47.6, Dart 3.13.5), which satisfies `sdk: ^3.11.5`. `/etc/profile.d/flutter.sh` prepends `/opt/flutter/bin` to `PATH`. If a shell cannot find `flutter`, export that path.

Chrome is already on the machine (`google-chrome`). Web is the supported preview target. Linux desktop and Android are not set up (`ninja`, GTK dev libraries, and the Android SDK are missing). Do not try to run an Android emulator here.

Story player without authentication:

```
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 -t lib/main_story_preview.dart
```

If you use the Chrome device instead, this VM needs extra browser flags:

```
flutter run -d chrome -t lib/main_story_preview.dart --web-browser-flag=--no-sandbox --web-browser-flag=--disable-dev-shm-usage
```

Tests:

```
flutter test
```

On Flutter 3.47.6 the suite finishes with 6 failures in `test/widget_test.dart` (profile logout, home search back navigation, home story card, CMS story card scroll, compact home layout, and continue listening). The rest pass. Those failures are in the existing widget suite and do not block `lib/main_story_preview.dart`.

`flutter test` and `flutter run` rewrite `analysis_options.yaml` to exclude platform directories. That is a local SDK side effect. Do not commit it unless you intend to change analyzer config.

`npm install` is only for the Supabase CLI in `package.json`. Local Supabase (`supabase start`) needs Docker, which is not installed. The checked-in `supabase/migrations` are schema for the remote project, not a server you can run in this environment.

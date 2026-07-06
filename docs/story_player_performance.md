# Story player performance testing

Use `lib/main_story_preview.dart` to test the real story UI and Supabase
assets without passing through unfinished authentication.

## Development

Use debug mode only for implementation and hot reload:

```powershell
flutter run -d chrome -t lib/main_story_preview.dart
```

## Performance checks

Use profile mode with Chrome DevTools when investigating frame timing,
network requests, or memory:

```powershell
flutter run -d chrome --profile -t lib/main_story_preview.dart --dart-define=STORY_PERFORMANCE_METRICS=true
```

Use release mode for final user-perceived checks:

```powershell
flutter run -d chrome --release -t lib/main_story_preview.dart --dart-define=STORY_PERFORMANCE_METRICS=true
```

The same modes are available from VS Code's Run and Debug menu as
`Story Preview - Chrome Debug`, `Story Preview - Chrome Profile`, and
`Story Preview - Chrome Release`.

Before comparing results:

1. Close unrelated high-CPU tabs and disable DevTools screenshots.
2. Test once with a cold browser cache, then repeat with a warm cache.
3. Play at least three pages and flip forward and backward.
4. Record the build mode with every result; never compare debug timings with
   profile or release timings.

Filter the Chrome console for `STORY_PERF`. Each line is structured JSON and
reports one of these metrics:

- `story_load` and `story_load_failed`
- `page_transition`
- `image_render`
- `audio_start_latency`
- `supabase_request_count`
- `image_cache_memory`

To verify that production compilation succeeds without launching Chrome:

```powershell
flutter build web --release -t lib/main_story_preview.dart
```

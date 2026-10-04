# Dharma Stories

## Story player preview

Run the real story player in Chrome without unfinished authentication:

```powershell
flutter run -d chrome -t lib/main_story_preview.dart
```

For realistic performance checks, use the
[story player performance runbook](docs/story_player_performance.md).

## Point the app at a backend on another VPS

This repository is the Flutter client. Audiobook stories, CMS design config, profiles, favorites, and listening history come from the backend API. Auth and media buckets come from Supabase.

1. Copy `.env.example` to `.env`.
2. Set `BACKEND_BASE_URL` to the backend origin on the VPS, with no trailing slash. The hosted API is `http://187.126.117.228`.
3. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the Supabase project that backend uses. That can be Supabase Cloud or Supabase self-hosted on the same VPS.
4. Restart the app. `.env` is bundled as an asset, so a running session does not pick up edits until the next build.

The CMS admin is not in this repository. Host that app on the VPS separately, and keep it writing to the same backend and Supabase project this client reads. The client loads CMS stories from `/api/v1/stories` and CMS design tokens from `/api/v1/public-app-config`.

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

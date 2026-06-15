import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/profile_notifier.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final sessionKey = session.when(
      loading: () => 'loading',
      error: (error, stackTrace) => 'error',
      data: (identity) => identity?.userId ?? 'signed-out',
    );

    return MaterialApp(
      key: ValueKey(sessionKey),
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: AppSessionGate(session: session),
    );
  }
}

class AppSessionGate extends ConsumerWidget {
  const AppSessionGate({required this.session, super.key});

  final AsyncValue<AppSessionIdentity?> session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return session.when(
      loading: () => const _StartupScreen(),
      error: (error, stackTrace) => const WelcomeScreen(),
      data: (currentSession) {
        if (currentSession == null) {
          return const WelcomeScreen();
        }

        final profiles = ref.watch(profileNotifierProvider);
        return profiles.when(
          loading: () => const _StartupScreen(),
          error: (error, stackTrace) => _StartupErrorScreen(
            onRetry: () => ref.invalidate(profileNotifierProvider),
          ),
          data: (state) => state.children.isEmpty
              ? const ProfileSetupScreen()
              : HomeScreen(
                  childName: state.selectedChild?.childName,
                  childAge: state.selectedChild?.age,
                ),
        );
      },
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: onRetry,
          child: const Text('Retry loading profiles'),
        ),
      ),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

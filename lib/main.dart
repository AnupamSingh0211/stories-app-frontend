import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/analytics_service.dart';
import 'core/notifications/notification_deeplink_router.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_token_repository.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/assets_provider.dart';
import 'features/auth/choose_companion_screen.dart';
import 'features/auth/companion_flow.dart';
import 'features/auth/profile_notifier.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/home/home_screen.dart';
import 'features/storytime/providers/story_player_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await dotenv.load();
    await _initializeConfiguredFirebase();
    if (_isAndroidFirebaseTarget) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await NotificationService.instance.initializeMessageHandlers();
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    await PostHogAnalytics.instance.setup();
  } catch (_) {
    FlutterNativeSplash.remove();
    rethrow;
  }

  runApp(const ProviderScope(child: MyApp()));
  FlutterNativeSplash.remove();
}

Future<void> _initializeConfiguredFirebase() async {
  if (!_isAndroidFirebaseTarget) {
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

bool get _isAndroidFirebaseTarget =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

    ref.listen<AsyncValue<AppSessionIdentity?>>(authSessionProvider, (
      previous,
      next,
    ) {
      next.whenData((identity) {
        if (identity == null) {
          unawaited(PostHogAnalytics.instance.resetUser());
          unawaited(NotificationService.instance.resetUser());
          return;
        }

        unawaited(
          PostHogAnalytics.instance.identifyUser(
            identity.userId,
            properties: {
              'auth_source': DevOtpAuthConfig.enabled
                  ? 'dev_backend_otp'
                  : 'supabase',
            },
          ),
        );
        NotificationDeepLinkRouter.instance.setStoryRepository(
          ref.read(storyRepositoryProvider),
        );
        unawaited(
          NotificationService.instance.registerDeviceForUser(
            identity.userId,
            tokenRepository: ref.read(notificationTokenRepositoryProvider),
          ),
        );
        unawaited(NotificationDeepLinkRouter.instance.flushPending());
      });
    });

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: AppSessionGate(session: session),
    );
  }
}

class _AuthMascotPrecacheGate extends ConsumerStatefulWidget {
  const _AuthMascotPrecacheGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_AuthMascotPrecacheGate> createState() =>
      _AuthMascotPrecacheGateState();
}

class _AuthMascotPrecacheGateState
    extends ConsumerState<_AuthMascotPrecacheGate> {
  Future<void>? _precacheFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mascotUrl = ref.read(appAssetsProvider)['mascot_character'];
    _precacheFuture ??= mascotUrl == null || mascotUrl.isEmpty
        ? Future<void>.value()
        : precacheImage(CachedNetworkImageProvider(mascotUrl), context)
              .timeout(const Duration(seconds: 3), onTimeout: () {})
              .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _precacheFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasError) {
          return const _StartupScreen();
        }

        return widget.child;
      },
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
      error: (error, stackTrace) =>
          const _AuthMascotPrecacheGate(child: WelcomeScreen()),
      data: (currentSession) {
        if (currentSession == null) {
          return const _AuthMascotPrecacheGate(child: WelcomeScreen());
        }

        final profiles = ref.watch(profileNotifierProvider);
        return profiles.when(
          loading: () => const _StartupScreen(),
          error: (error, stackTrace) {
            if (DevOtpAuthConfig.enabled) {
              return const HomeScreen();
            }

            return _StartupErrorScreen(
              onRetry: () => ref.invalidate(profileNotifierProvider),
            );
          },
          data: (state) {
            if (state.children.isEmpty) {
              if (DevOtpAuthConfig.enabled) {
                _flushPendingNotificationDeepLink();
                return const HomeScreen();
              }

              return const ProfileSetupScreen();
            }

            final selectedChild = state.selectedChild;
            if (ref.watch(companionSelectionPendingProvider)) {
              return ChooseCompanionScreen(
                onComplete: (context) {
                  ProviderScope.containerOf(
                        context,
                        listen: false,
                      ).read(companionSelectionPendingProvider.notifier).state =
                      false;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              );
            }

            _flushPendingNotificationDeepLink();
            return HomeScreen(
              childName: selectedChild?.childName,
              childAge: selectedChild?.age,
            );
          },
        );
      },
    );
  }
}

void _flushPendingNotificationDeepLink() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(NotificationDeepLinkRouter.instance.flushPending());
  });
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

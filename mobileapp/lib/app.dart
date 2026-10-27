import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'screens/add_email_screen.dart';
import 'screens/check_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_code_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_pick_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/startup_screen.dart';
import 'session.dart';
import 'widgets/fc_tab_bar.dart';
import 'widgets/waking_banner.dart';

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    super.key,
    required SessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope not found');
    return scope!.notifier!;
  }
}

GoRouter createRouter(SessionController session) {
  return GoRouter(
    initialLocation: '/starting',
    refreshListenable: session,
    redirect: (context, state) {
      final starting = state.matchedLocation == '/starting';
      if (!session.ready || session.startupError != null) {
        return starting ? null : '/starting';
      }
      if (starting) {
        return session.authenticated ? '/' : '/login';
      }
      final location = state.matchedLocation;
      final loggingIn = location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password';
      final verifying = location == '/verify-code';
      // Older accounts must add an email before anything else.
      if (session.authenticated && session.needsEmail) {
        return location == '/add-email' || verifying ? null : '/add-email';
      }
      if (!session.authenticated && !loggingIn && !verifying) {
        return '/login';
      }
      if (session.authenticated &&
          (loggingIn || verifying || location == '/add-email')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/starting',
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-code',
        builder: (context, state) {
          final args = state.extra;
          // A lost `extra` (e.g. a browser refresh) has nothing to verify.
          return args is VerifyCodeArgs
              ? VerifyCodeScreen(args: args)
              : const LoginScreen();
        },
      ),
      GoRoute(
        path: '/add-email',
        builder: (context, state) => const AddEmailScreen(),
      ),
      // The four main screens share the tab bar.
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) => const SavedScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/search-restaurants',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/pick-restaurant',
        builder: (context, state) => const MapPickScreen(),
      ),
      GoRoute(
        path: '/check-restaurant',
        builder: (context, state) => CheckScreen(
          request:
              state.extra is CheckRequest ? state.extra as CheckRequest : null,
        ),
      ),
    ],
  );
}

class MenuApp extends StatefulWidget {
  const MenuApp({super.key, required this.session});

  final SessionController session;

  @override
  State<MenuApp> createState() => _MenuAppState();
}

class _MenuAppState extends State<MenuApp> with WidgetsBindingObserver {
  late final GoRouter _router = createRouter(widget.session);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back after a long time away: start waking the server now so the
    // banner shows up before the user taps anything.
    if (state == AppLifecycleState.resumed && widget.session.ready) {
      widget.session.api.wakeIfIdle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: widget.session,
      child: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) => MaterialApp.router(
          title: 'Forkcast',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: widget.session.themeMode,
          routerConfig: _router,
          // The waking banner shows mid-session only; the startup screen covers
          // the launch case, so it stays hidden until the session is ready.
          builder: (context, child) => ListenableBuilder(
            listenable: widget.session,
            builder: (context, _) => ValueListenableBuilder<bool>(
              valueListenable: widget.session.api.serverWaking,
              builder: (context, waking, _) => WakingBannerHost(
                show: waking &&
                    widget.session.ready &&
                    widget.session.startupError == null,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showApiError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

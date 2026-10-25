import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'screens/check_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_pick_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/search_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/startup_screen.dart';
import 'session.dart';
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
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (!session.authenticated && !loggingIn) {
        return '/login';
      }
      if (session.authenticated && loggingIn) {
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
        path: '/',
        builder: (context, state) => const HomeScreen(),
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
          request: state.extra is CheckRequest
              ? state.extra as CheckRequest
              : null,
        ),
      ),
      GoRoute(
        path: '/saved',
        builder: (context, state) => const SavedScreen(),
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
      child: MaterialApp.router(
        title: 'Forkcast',
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.system,
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
    );
  }
}

void showApiError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

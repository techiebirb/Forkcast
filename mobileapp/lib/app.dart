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
        builder: (context, state) => const CheckScreen(),
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
        theme: buildAppTheme(),
        routerConfig: _router,
        builder: (context, child) => Stack(
          children: [
            if (child != null) child,
            _WakingBanner(session: widget.session),
          ],
        ),
      ),
    );
  }
}

/// Slim banner shown mid-session while the server is waking up. The startup
/// screen covers the app-launch case, so it is hidden until the session is
/// ready.
class _WakingBanner extends StatelessWidget {
  const _WakingBanner({required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ValueListenableBuilder<bool>(
        valueListenable: session.api.serverWaking,
        builder: (context, waking, _) {
          final show = waking && session.ready && session.startupError == null;
          return Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              ignoring: !show,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                offset: show ? Offset.zero : const Offset(0, -1.5),
                child: const Material(
                  color: kAccent,
                  elevation: 4,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Waking up the server — this can take up to a '
                              'minute.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LoadingBarrier extends StatelessWidget {
  const LoadingBarrier({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black38,
      alignment: Alignment.center,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
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

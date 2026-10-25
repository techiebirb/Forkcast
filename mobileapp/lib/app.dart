import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api_client.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/widgets.dart';
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
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: ThemeMode.system,
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

/// Accent strip docked at the top while the server wakes up mid-session.
/// The startup screen covers the app-launch case, so it is hidden until the
/// session is ready. It never takes taps, so the screen below keeps working.
class _WakingBanner extends StatelessWidget {
  const _WakingBanner({required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ValueListenableBuilder<bool>(
        valueListenable: session.api.serverWaking,
        builder: (context, waking, _) {
          final show = waking && session.ready && session.startupError == null;
          return Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: FcMotion.of(context, FcMotion.sheet),
                curve: FcMotion.ease,
                offset: show ? Offset.zero : const Offset(0, -1.5),
                child: Semantics(
                  liveRegion: show,
                  child: ColoredBox(
                    color: c.accent,
                    child: SafeArea(
                      bottom: false,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 36,
                          minWidth: double.infinity,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: FcSpace.s4,
                            vertical: FcSpace.s2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FcSpinner(size: 14, color: c.onAccent),
                              const SizedBox(width: FcSpace.s2),
                              Flexible(
                                child: Text(
                                  'Waking up the server. This can take a '
                                  'minute.',
                                  textAlign: TextAlign.center,
                                  style: context.text.labelMedium!.copyWith(
                                    color: c.onAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
    final c = context.fc;
    return Container(
      color: c.scrim,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(FcSpace.s8),
        padding: const EdgeInsets.all(FcSpace.s6),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(FcRadius.card),
          border: Border.all(color: c.border),
        ),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FcSpinner(size: 24, color: c.accent),
              const SizedBox(height: FcSpace.s4),
              Text(message, textAlign: TextAlign.center),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'screens/check_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_pick_screen.dart';
import 'screens/search_screen.dart';
import 'screens/signup_screen.dart';
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
    initialLocation: '/login',
    refreshListenable: session,
    redirect: (context, state) {
      if (!session.ready) {
        return null;
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
    ],
  );
}

class MenuApp extends StatefulWidget {
  const MenuApp({super.key, required this.session});

  final SessionController session;

  @override
  State<MenuApp> createState() => _MenuAppState();
}

class _MenuAppState extends State<MenuApp> {
  late final GoRouter _router = createRouter(widget.session);

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: widget.session,
      child: MaterialApp.router(
        title: 'Menu Match',
        theme: buildAppTheme(),
        routerConfig: _router,
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

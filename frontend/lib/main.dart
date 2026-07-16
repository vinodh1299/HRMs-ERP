import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/me/me_dashboard.dart';
import 'screens/mail/mail_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/org/org_screen.dart';
import 'screens/stubs/empty_state_screen.dart';
import 'widgets/sidebar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final GoRouter router = GoRouter(
      initialLocation: '/',
      refreshListenable: _RiverpodListenable(ref),
      redirect: (context, state) {
        final isAuthenticated = authState.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuthenticated) {
          return '/login';
        }

        if (isLoggingIn) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return NavigationShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/me',
              builder: (context, state) => const MeDashboardScreen(),
            ),
            GoRoute(
              path: '/mail',
              builder: (context, state) => const MailScreen(),
            ),
            GoRoute(
              path: '/chat',
              builder: (context, state) => const ChatScreen(),
            ),
            GoRoute(
              path: '/org',
              builder: (context, state) => const OrgScreen(),
            ),
            GoRoute(
              path: '/stubs/:module',
              builder: (context, state) {
                final module = state.pathParameters['module'] ?? 'Unknown';
                // Capitalize first letter
                final moduleName = module[0].toUpperCase() + module.substring(1);
                return EmptyStateScreen(moduleName: moduleName);
              },
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'ACA Portal',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Helper to make Riverpod state updates notify GoRouter for redirection
class _RiverpodListenable extends ChangeNotifier {
  _RiverpodListenable(WidgetRef ref) {
    ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

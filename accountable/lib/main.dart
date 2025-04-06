import 'package:accountable/backend/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:accountable/presentation/pages/home_page.dart';
import 'package:accountable/presentation/pages/file_upload_screen.dart';
import 'package:accountable/presentation/pages/summary_screen.dart';
import 'package:accountable/presentation/pages/transaction_details_screen.dart';
import 'package:provider/provider.dart';

// --- Global Navigator Keys ---
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomePageKey =
    GlobalKey<NavigatorState>(debugLabel: 'HomePage');
final _shellNavigatorNewPageKey =
    GlobalKey<NavigatorState>(debugLabel: 'NewPage');
final _shellNavigatorSummaryPageKey =
    GlobalKey<NavigatorState>(debugLabel: 'SummaryPage');

// --- App Router Setup ---
final GoRouter goRouter = GoRouter(
  initialLocation: '/HomePage',
  navigatorKey: _rootNavigatorKey,
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
      },
      branches: [
        // --- Home Page Branch ---
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHomePageKey,
          routes: [
            GoRoute(
              path: '/HomePage',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomePage(detailsPath: '/HomePage/transaction_details'),
              ),
              routes: [
                GoRoute(
                  path: 'transaction_details',
                  builder: (context, state) {
                    final transaction = state.extra as Trans;
                    return TransactionDetailScreen(transaction: transaction);
                  },
                ),
              ],
            ),
          ],
        ),

        // --- Upload Page Branch ---
        StatefulShellBranch(
          navigatorKey: _shellNavigatorNewPageKey,
          routes: [
            GoRoute(
              path: '/UploadPage',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: FileUploadScreen(),
              ),
            ),
          ],
        ),

        // --- Summary Page Branch ---
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSummaryPageKey,
          routes: [
            GoRoute(
              path: '/SummaryPage',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: BudgetSummaryScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() async {
  usePathUrlStrategy(); // clean URLs on web

  // Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => TransList(),
        ),
        ChangeNotifierProvider(
          create: (context) => AppState(),
        ),
      ],
      child: const MyApp(), // still the same widget
    ),
  );
}

// --- App Entry ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
    );
  }
}

// --- Nested Navigation Scaffold ---
class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavigationBar(
      body: navigationShell,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _goBranch,
    );
  }
}

// --- Bottom Navigation Scaffold ---
class ScaffoldWithNavigationBar extends StatelessWidget {
  const ScaffoldWithNavigationBar({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(label: 'Home', icon: Icon(Icons.home)),
          NavigationDestination(label: 'New', icon: Icon(Icons.add)),
          NavigationDestination(label: 'Summary', icon: Icon(Icons.add_chart)),
        ],
      ),
    );
  }
}

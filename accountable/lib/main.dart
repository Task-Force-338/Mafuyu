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
      theme: ThemeData(
        // Primary color - Muted Purple-Grey / Deep Indigo
        primaryColor: const Color(0xFF6A5E7A),
        primarySwatch: Colors.indigo,

        // Background colors - Dark Greys, Dark Primary Shades
        scaffoldBackgroundColor: const Color(0xFF2D2B35),

        // Card & Surface colors
        cardColor: const Color(0xFF3A364A),
        canvasColor: const Color(0xFF32303D),

        // Text colors - Light Grey / Off-White for readability
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
          titleLarge: TextStyle(color: Color(0xFFE0E0E0)),
          titleMedium: TextStyle(color: Color(0xFFE0E0E0)),
          titleSmall: TextStyle(color: Color(0xFFE0E0E0)),
        ),

        // Accent colors - Pale Lavender, Desaturated Light Blue/Cyan
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6A5E7A),
          secondary: const Color(0xFF888888), // Mafuyu's official color
          tertiary: const Color(0xFF9B8EB8), // Pale Lavender accent
          surface: const Color(0xFF3A364A),
          background: const Color(0xFF2D2B35),
          error: Colors.red.shade300,
          onPrimary: const Color(0xFFE0E0E0),
          onSecondary: const Color(0xFFE0E0E0),
          onSurface: const Color(0xFFE0E0E0),
          onBackground: const Color(0xFFE0E0E0),
        ),

        // Button colors
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A5E7A),
            foregroundColor: const Color(0xFFE0E0E0),
          ),
        ),

        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3A364A),
          foregroundColor: Color(0xFFE0E0E0),
        ),

        // Bottom navigation bar theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF3A364A),
          selectedItemColor: Color(0xFF9B8EB8), // Pale Lavender accent
          unselectedItemColor: Color(0xFF888888), // Medium Grey
        ),
      ),
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
        backgroundColor: const Color(0xFF3A364A),
        indicatorColor: const Color(0xFF6A5E7A),
        destinations: const [
          NavigationDestination(
            label: 'Home',
            icon: Icon(Icons.home, color: Color(0xFF888888)),
            selectedIcon: Icon(Icons.home, color: Color(0xFFE0E0E0)),
          ),
          NavigationDestination(
            label: 'New',
            icon: Icon(Icons.add, color: Color(0xFF888888)),
            selectedIcon: Icon(Icons.add, color: Color(0xFFE0E0E0)),
          ),
          NavigationDestination(
            label: 'Summary',
            icon: Icon(Icons.add_chart, color: Color(0xFF888888)),
            selectedIcon: Icon(Icons.add_chart, color: Color(0xFFE0E0E0)),
          ),
        ],
      ),
    );
  }
}

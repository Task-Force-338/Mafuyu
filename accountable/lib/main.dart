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
        // Primary color - Richer Purple-Grey
        primaryColor: const Color(0xFF7A6B8D),
        primarySwatch: Colors.indigo,

        // Background colors - Improved dark theme
        scaffoldBackgroundColor: const Color(0xFF2A2832),

        // Card & Surface colors with shadows
        cardColor: const Color(0xFF3A364A),
        canvasColor: const Color(0xFF32303D),

        // Text colors - Better contrast
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFFF0F0F0),
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFF0F0F0),
            fontWeight: FontWeight.w400,
          ),
          titleLarge: TextStyle(
            color: Color(0xFFF0F0F0),
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: Color(0xFFF0F0F0),
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            color: Color(0xFFF0F0F0),
            fontWeight: FontWeight.w500,
          ),
        ),

        // Accent colors - More vibrant
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF7A6B8D),
          secondary: const Color(0xFF9B8EB8), // Updated secondary color
          tertiary: const Color(0xFFAEA0CC), // Brighter accent
          surface: const Color(0xFF3A364A),
          background: const Color(0xFF2A2832),
          error: Colors.red.shade300,
          onPrimary: const Color(0xFFF0F0F0),
          onSecondary: const Color(0xFFF0F0F0),
          onSurface: const Color(0xFFF0F0F0),
          onBackground: const Color(0xFFF0F0F0),
        ),

        // Improved button styles
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A6B8D),
            foregroundColor: const Color(0xFFF0F0F0),
            elevation: 4,
            shadowColor: const Color(0x667A6B8D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),

        // Improved app bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3F3749),
          foregroundColor: Color(0xFFF0F0F0),
          elevation: 4,
          shadowColor: Color(0x66000000),
          centerTitle: true,
        ),

        // Improved bottom navigation bar theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF3F3749),
          selectedItemColor: Color(0xFFAEA0CC), // Brighter accent
          unselectedItemColor:
              Color(0xAABBBBBB), // More visible unselected items
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),

        // Better card theme
        cardTheme: CardTheme(
          color: const Color(0xFF3A364A),
          elevation: 4,
          shadowColor: const Color(0x66000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),

        // Better input decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF32303D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFAEA0CC), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFFBBBBBB)),
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: const Color(0xFF3F3749),
          indicatorColor: const Color(0x557A6B8D),
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          animationDuration: const Duration(milliseconds: 300),
          destinations: const [
            NavigationDestination(
              label: 'Home',
              icon:
                  Icon(Icons.home_outlined, color: Color(0xAABBBBBB), size: 26),
              selectedIcon:
                  Icon(Icons.home, color: Color(0xFFAEA0CC), size: 28),
            ),
            NavigationDestination(
              label: 'Add',
              icon: Icon(Icons.add_circle_outline,
                  color: Color(0xAABBBBBB), size: 26),
              selectedIcon:
                  Icon(Icons.add_circle, color: Color(0xFFAEA0CC), size: 28),
            ),
            NavigationDestination(
              label: 'Summary',
              icon: Icon(Icons.insert_chart_outlined,
                  color: Color(0xAABBBBBB), size: 26),
              selectedIcon:
                  Icon(Icons.insert_chart, color: Color(0xFFAEA0CC), size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

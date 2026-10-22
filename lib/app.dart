import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/theme.dart';
import 'data/kitchen.dart';
import 'data/recipe_repository.dart';
import 'data/settings.dart';
import 'ui/screens/add_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/kitchen_screen.dart';
import 'ui/screens/language_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/saved_screen.dart';

class OzoumaApp extends StatelessWidget {
  const OzoumaApp({
    super.key,
    required this.settings,
    required this.recipes,
    required this.kitchen,
    this.remoteFonts = true,
  });

  final AppSettings settings;
  final RecipeRepository recipes;
  final Kitchen kitchen;

  /// False in tests so fonts are not downloaded.
  final bool remoteFonts;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final arabic = settings.arabic;
        return AppScope(
          settings: settings,
          recipes: recipes,
          kitchen: kitchen,
          child: MaterialApp(
            title: 'Ozouma',
            debugShowCheckedModeBanner: false,
            theme: OzTheme.build(arabic: arabic, remoteFonts: remoteFonts),
            locale: Locale(arabic ? 'ar' : 'en', arabic ? 'EG' : 'US'),
            supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: settings.chosenLanguage ? const HomeShell() : const LanguageScreen(),
          ),
        );
      },
    );
  }
}

/// The five tabs: Home, Add, Kitchen, Saved, Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _goTo(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenKitchen: () => _goTo(2)),
      AddScreen(onSaved: () => _goTo(3)),
      const KitchenScreen(),
      const SavedScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goTo,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: context.tr('tab_home')),
          NavigationDestination(icon: const Icon(Icons.add_circle_outline), selectedIcon: const Icon(Icons.add_circle), label: context.tr('tab_add')),
          NavigationDestination(icon: const Icon(Icons.kitchen_outlined), selectedIcon: const Icon(Icons.kitchen), label: context.tr('tab_kitchen')),
          NavigationDestination(icon: const Icon(Icons.bookmark_border), selectedIcon: const Icon(Icons.bookmark), label: context.tr('tab_saved')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: context.tr('tab_profile')),
        ],
      ),
    );
  }
}

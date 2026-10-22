import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozouma/app.dart';
import 'package:ozouma/core/app_scope.dart';
import 'package:ozouma/core/theme.dart';
import 'package:ozouma/data/kitchen.dart';
import 'package:ozouma/data/recipe_repository.dart';
import 'package:ozouma/data/settings.dart';
import 'package:ozouma/ui/screens/cooking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void phoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('pick English, browse, open a recipe', (tester) async {
    phoneSize(tester);
    final prefs = await SharedPreferences.getInstance();
    final recipes = RecipeRepository(prefs);
    await tester.runAsync(recipes.load);
    await tester.pumpWidget(OzoumaApp(
      settings: AppSettings(prefs),
      recipes: recipes,
      kitchen: Kitchen(prefs),
      remoteFonts: false,
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Choose your language'), findsWidgets);
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What are we cooking today?'), findsOneWidget);
    expect(find.text('Koshari'), findsWidgets);

    await tester.ensureVisible(find.text('Koshari').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koshari').first);
    await tester.pumpAndSettle();
    expect(find.text('Start cooking'), findsOneWidget);
    expect(find.text('Ingredients'), findsWidgets);
  });

  testWidgets('cooking mode moves between steps and counts in a timer', (tester) async {
    phoneSize(tester);
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(prefs);
    await settings.setLanguage(false);
    final recipes = RecipeRepository(prefs);
    await tester.runAsync(recipes.load);
    final recipe = recipes.byId('shakshuka')!;

    await tester.pumpWidget(AppScope(
      settings: settings,
      recipes: recipes,
      kitchen: Kitchen(prefs),
      child: MaterialApp(
        theme: OzTheme.build(arabic: false, remoteFonts: false),
        home: CookingScreen(recipe: recipe, enableDeviceFeatures: false),
      ),
    ));
    await tester.pump();

    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text(recipe.steps.first.text.en), findsOneWidget);
    expect(find.text('Timer starts in 3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('left'), findsWidgets);

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Step 2 of 6'), findsOneWidget);

    // Dispose the screen so its ticker stops.
    await tester.pumpWidget(const SizedBox());
  });
}

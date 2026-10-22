import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/kitchen.dart';
import 'data/recipe_repository.dart';
import 'data/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final recipes = RecipeRepository(prefs);
  await recipes.load();
  runApp(OzoumaApp(
    settings: AppSettings(prefs),
    recipes: recipes,
    kitchen: Kitchen(prefs),
  ));
}

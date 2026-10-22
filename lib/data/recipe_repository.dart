import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/text_normalize.dart';
import '../models/recipe.dart';

/// Curated recipes from the app bundle, plus the cook's saved and imported
/// recipes stored on the device.
class RecipeRepository extends ChangeNotifier {
  RecipeRepository(this._prefs);

  final SharedPreferences? _prefs;

  List<Recipe> _curated = const [];
  List<Recipe> _imported = [];
  List<PantryItem> _pantryItems = const [];
  Set<String> _saved = {};
  Map<String, int> _cooked = {};

  List<Recipe> get curated => _curated;
  List<Recipe> get imported => _imported;
  List<Recipe> get all => [..._curated, ..._imported];
  List<PantryItem> get pantryItems => _pantryItems;

  Future<void> load({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    final recipesJson = jsonDecode(await b.loadString('assets/data/recipes.json')) as List;
    _curated = recipesJson.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    final itemsJson = jsonDecode(await b.loadString('assets/data/ingredients.json')) as List;
    _pantryItems = itemsJson.map((e) => PantryItem.fromJson(e as Map<String, dynamic>)).toList();

    final stored = _prefs?.getString('imported_recipes');
    if (stored != null) {
      _imported = (jsonDecode(stored) as List).map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    }
    _saved = (_prefs?.getStringList('saved_ids') ?? const []).toSet();
    final cooked = _prefs?.getString('cooked_counts');
    if (cooked != null) {
      _cooked = (jsonDecode(cooked) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    }
    notifyListeners();
  }

  /// Loads from given data, used by tests.
  void loadFrom({required List<Recipe> curated, List<PantryItem> pantryItems = const []}) {
    _curated = curated;
    _pantryItems = pantryItems;
    notifyListeners();
  }

  Recipe? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  PantryItem? pantryItem(String id) {
    for (final p in _pantryItems) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool isSaved(String id) => _saved.contains(id) || _imported.any((r) => r.id == id);
  int cookedCount(String id) => _cooked[id] ?? 0;

  List<Recipe> get saved => [
        ..._imported.reversed,
        ..._curated.where((r) => _saved.contains(r.id)),
      ];

  Future<void> toggleSaved(String id) async {
    if (!_saved.remove(id)) _saved.add(id);
    await _prefs?.setStringList('saved_ids', _saved.toList());
    notifyListeners();
  }

  Future<void> addImported(Recipe recipe) async {
    _imported.removeWhere((r) => r.id == recipe.id);
    _imported.add(recipe);
    await _persistImported();
    notifyListeners();
  }

  Future<void> deleteImported(String id) async {
    _imported.removeWhere((r) => r.id == id);
    await _persistImported();
    notifyListeners();
  }

  Future<void> markCooked(String id) async {
    _cooked[id] = cookedCount(id) + 1;
    await _prefs?.setString('cooked_counts', jsonEncode(_cooked));
    notifyListeners();
  }

  /// Search by title, tag or ingredient in either language.
  List<Recipe> search(String query, {String? tag}) {
    final q = normalizeText(query);
    return all.where((r) {
      if (tag != null && !r.tags.contains(tag)) {
        if (!(tag == 'quick' && r.minutes > 0 && r.minutes <= 30)) return false;
      }
      if (q.isEmpty) return true;
      final hay = normalizeText([
        r.title.en,
        r.title.ar,
        ...r.ingredients.expand((i) => [i.name.en, i.name.ar]),
      ].join(' '));
      return hay.contains(q);
    }).toList();
  }

  Future<void> _persistImported() async {
    await _prefs?.setString('imported_recipes', jsonEncode(_imported.map((r) => r.toJson()).toList()));
  }
}

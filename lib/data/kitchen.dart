import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';

class ShoppingItem {
  ShoppingItem({required this.key, required this.name, this.amount = '', this.checked = false});

  /// Canonical ingredient id, or the name for free text items.
  final String key;
  final Bilingual name;
  String amount;
  bool checked;

  Map<String, dynamic> toJson() => {'key': key, 'name': name.toJson(), 'amount': amount, 'checked': checked};

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        key: j['key'] as String,
        name: Bilingual.fromJson(j['name']),
        amount: (j['amount'] ?? '') as String,
        checked: (j['checked'] ?? false) as bool,
      );
}

/// How well a recipe fits what is in the pantry.
class RecipeMatch {
  const RecipeMatch(this.recipe, this.missing);

  final Recipe recipe;

  /// Ingredient ids the cook still needs (staples excluded).
  final List<String> missing;
}

/// The pantry ("what I have") and the shopping list.
class Kitchen extends ChangeNotifier {
  Kitchen(this._prefs) {
    _pantry = (_prefs?.getStringList('pantry') ?? const []).toSet();
    final list = _prefs?.getString('shopping');
    if (list != null) {
      _shopping = (jsonDecode(list) as List).map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  final SharedPreferences? _prefs;
  Set<String> _pantry = {};
  List<ShoppingItem> _shopping = [];

  Set<String> get pantry => _pantry;
  List<ShoppingItem> get shopping => _shopping;

  bool has(String id) => _pantry.contains(id);

  Future<void> togglePantry(String id) async {
    if (!_pantry.remove(id)) _pantry.add(id);
    await _prefs?.setStringList('pantry', _pantry.toList());
    notifyListeners();
  }

  /// Recipes ordered by how few ingredients are missing. Staples such as salt,
  /// oil and water are assumed to be at home.
  List<RecipeMatch> match(List<Recipe> recipes, List<PantryItem> items) {
    final staples = items.where((i) => i.staple).map((i) => i.id).toSet();
    final results = <RecipeMatch>[];
    for (final r in recipes) {
      final needed = r.ingredients.map((i) => i.id).where((id) => id.isNotEmpty && !staples.contains(id)).toSet();
      if (needed.isEmpty) continue;
      final missing = needed.where((id) => !_pantry.contains(id)).toList();
      if (missing.length == needed.length) continue; // nothing in common
      results.add(RecipeMatch(r, missing));
    }
    results.sort((a, b) => a.missing.length.compareTo(b.missing.length));
    return results;
  }

  /// Adds a recipe's ingredients to the list, skipping what is in the pantry
  /// and merging duplicates. Returns how many items were added.
  Future<int> addRecipe(Recipe recipe, {required String Function(Ingredient) amountOf}) async {
    var added = 0;
    for (final ing in recipe.ingredients) {
      if (ing.id.isNotEmpty && _pantry.contains(ing.id)) continue;
      final key = ing.id.isNotEmpty ? ing.id : ing.name.en + ing.name.ar;
      final existing = _shopping.where((s) => s.key == key).toList();
      final amount = amountOf(ing);
      if (existing.isNotEmpty) {
        final item = existing.first;
        if (amount.isNotEmpty && !item.amount.contains(amount)) {
          item.amount = item.amount.isEmpty ? amount : '${item.amount} + $amount';
        }
        item.checked = false;
      } else {
        _shopping.add(ShoppingItem(key: key, name: ing.name, amount: amount));
        added++;
      }
    }
    await _persist();
    notifyListeners();
    return added;
  }

  Future<void> toggleChecked(ShoppingItem item) async {
    item.checked = !item.checked;
    await _persist();
    notifyListeners();
  }

  Future<void> clearChecked() async {
    _shopping.removeWhere((s) => s.checked);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(ShoppingItem item) async {
    _shopping.remove(item);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _prefs?.setString('shopping', jsonEncode(_shopping.map((s) => s.toJson()).toList()));
  }
}

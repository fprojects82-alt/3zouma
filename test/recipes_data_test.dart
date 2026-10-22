import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ozouma/cooking/duration_parser.dart';
import 'package:ozouma/models/recipe.dart';

/// Checks the curated recipes so content edits cannot break cooking mode.
void main() {
  final recipes = (jsonDecode(File('assets/data/recipes.json').readAsStringSync()) as List)
      .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
      .toList();
  final pantryIds = (jsonDecode(File('assets/data/ingredients.json').readAsStringSync()) as List)
      .map((e) => (e as Map<String, dynamic>)['id'] as String)
      .toSet();

  test('recipes load with steps in both languages', () {
    expect(recipes, isNotEmpty);
    final ids = <String>{};
    for (final r in recipes) {
      expect(ids.add(r.id), isTrue, reason: 'duplicate id ${r.id}');
      expect(r.title.en, isNotEmpty);
      expect(r.title.ar, isNotEmpty);
      expect(r.steps, isNotEmpty);
      for (final s in r.steps) {
        expect(s.text.en, isNotEmpty, reason: '${r.id} step missing English');
        expect(s.text.ar, isNotEmpty, reason: '${r.id} step missing Arabic');
      }
    }
  });

  test('every ingredient uses a known pantry id', () {
    for (final r in recipes) {
      for (final i in r.ingredients) {
        expect(pantryIds.contains(i.id), isTrue, reason: '${r.id}: unknown ingredient ${i.id}');
      }
    }
  });

  test('English and Arabic agree on every timer', () {
    for (final r in recipes) {
      for (var i = 0; i < r.steps.length; i++) {
        final s = r.steps[i];
        // Read each language on its own (timer() falls back to the other one).
        final en = s.timerSeconds != null ? s.timer(false) : DurationParser.parse(s.text.en);
        final ar = s.timerSeconds != null ? s.timer(true) : DurationParser.parse(s.text.ar);
        expect(en, ar, reason: '${r.id} step ${i + 1}: "${s.text.en}" vs "${s.text.ar}"');
        if (s.timerLabel != null) {
          expect(en, isNotNull, reason: '${r.id} step ${i + 1} has a label but no time');
        }
      }
    }
  });
}

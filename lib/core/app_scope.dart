import 'package:flutter/widgets.dart';

import '../data/kitchen.dart';
import '../data/recipe_repository.dart';
import '../data/settings.dart';
import '../models/recipe.dart';
import 'numerals.dart';
import 'strings.dart';

/// Gives every screen access to settings, recipes and the kitchen, and
/// rebuilds them when any of these change.
class AppScope extends InheritedNotifier<Listenable> {
  AppScope({
    super.key,
    required this.settings,
    required this.recipes,
    required this.kitchen,
    required super.child,
  }) : super(notifier: Listenable.merge([settings, recipes, kitchen]));

  final AppSettings settings;
  final RecipeRepository recipes;
  final Kitchen kitchen;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!;
  }
}

extension AppContext on BuildContext {
  AppScope get app => AppScope.of(this);
  bool get isArabic => app.settings.arabic;
  Strings get strings => Strings(isArabic);
  String tr(String key) => strings.t(key);
  String trf(String key, Map<String, String> values) => strings.f(key, values);

  /// A number shown in the cook's chosen digits.
  String fmt(num value) => Numerals.format(value, eastern: app.settings.easternNumerals);
  String clock(Duration d) => Numerals.clock(d, eastern: app.settings.easternNumerals);
  String local(Bilingual b) => b.of(isArabic);

  /// "45 min" style label.
  String minutes(int m) => trf('minutes_short', {'n': fmt(m)});
}

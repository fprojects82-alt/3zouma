import 'package:flutter/widgets.dart';

import '../../core/app_scope.dart';
import '../../models/recipe.dart';

/// "1½ cup", "٢ كوباية", or "" when the ingredient has no quantity.
String ingredientAmount(BuildContext context, Ingredient ing, {double factor = 1}) {
  if (ing.qty == null) return '';
  final q = ing.qty! * factor;
  final whole = q.floor();
  final frac = q - whole;
  String number;
  const fractions = {0.25: '¼', 0.5: '½', 0.75: '¾'};
  String? sym;
  for (final e in fractions.entries) {
    if ((frac - e.key).abs() < 0.04) sym = e.value;
  }
  if (frac < 0.04) {
    number = context.fmt(whole);
  } else if ((1 - frac) < 0.04) {
    number = context.fmt(whole + 1);
  } else if (sym != null) {
    number = whole == 0 ? sym : '${context.fmt(whole)}$sym';
  } else {
    number = context.fmt(double.parse(q.toStringAsFixed(1)));
  }
  final unit = ing.unit == null ? '' : ' ${context.local(ing.unit!)}';
  return '$number$unit';
}

import '../cooking/duration_parser.dart';

/// Text in both languages. Imported recipes may only have one.
class Bilingual {
  const Bilingual({required this.en, required this.ar});

  final String en;
  final String ar;

  String of(bool arabic) {
    if (arabic) return ar.isNotEmpty ? ar : en;
    return en.isNotEmpty ? en : ar;
  }

  factory Bilingual.fromJson(dynamic json) {
    if (json is String) return Bilingual(en: json, ar: json);
    final map = json as Map<String, dynamic>;
    return Bilingual(en: (map['en'] ?? '') as String, ar: (map['ar'] ?? '') as String);
  }

  Map<String, dynamic> toJson() => {'en': en, 'ar': ar};
}

class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    this.qty,
    this.unit,
  });

  /// Canonical ingredient id, shared with the pantry and shopping list.
  /// Empty for free text ingredients from imports.
  final String id;
  final Bilingual name;
  final double? qty;
  final Bilingual? unit;

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: (json['id'] ?? '') as String,
        name: Bilingual.fromJson(json['name']),
        qty: (json['qty'] as num?)?.toDouble(),
        unit: json['unit'] == null ? null : Bilingual.fromJson(json['unit']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name.toJson(),
        if (qty != null) 'qty': qty,
        if (unit != null) 'unit': unit!.toJson(),
      };
}

class RecipeStep {
  const RecipeStep({required this.text, this.timerSeconds, this.timerLabel, this.videoSecond});

  final Bilingual text;

  /// Explicit timer. When null the duration is detected from the text.
  final int? timerSeconds;

  /// Short name for the timer, e.g. "Rice". Falls back to the step number.
  final Bilingual? timerLabel;

  /// Second in the source video where this step happens (video recipes).
  final int? videoSecond;

  Duration? timer(bool arabic) {
    if (timerSeconds != null) return timerSeconds! > 0 ? Duration(seconds: timerSeconds!) : null;
    return DurationParser.parse(text.of(arabic)) ?? DurationParser.parse(text.of(!arabic));
  }

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        text: Bilingual.fromJson(json['text']),
        timerSeconds: json['timer'] as int?,
        timerLabel: json['timerLabel'] == null ? null : Bilingual.fromJson(json['timerLabel']),
        videoSecond: json['videoSecond'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'text': text.toJson(),
        if (timerSeconds != null) 'timer': timerSeconds,
        if (timerLabel != null) 'timerLabel': timerLabel!.toJson(),
        if (videoSecond != null) 'videoSecond': videoSecond,
      };
}

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.minutes,
    required this.servings,
    required this.ingredients,
    required this.steps,
    this.tags = const [],
    this.color = 0xFF9C8670,
    this.sourceUrl,
    this.imported = false,
  });

  final String id;
  final Bilingual title;
  final int minutes;
  final int servings;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> tags;

  /// Placeholder colour for the photo area until real photography is added.
  final int color;
  final String? sourceUrl;
  final bool imported;

  int timerCount(bool arabic) => steps.where((s) => s.timer(arabic) != null).length;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        title: Bilingual.fromJson(json['title']),
        minutes: (json['minutes'] ?? 0) as int,
        servings: (json['servings'] ?? 2) as int,
        tags: ((json['tags'] ?? const []) as List).cast<String>(),
        color: json['color'] is String ? int.parse((json['color'] as String).replaceFirst('#', 'FF'), radix: 16) : (json['color'] ?? 0xFF9C8670) as int,
        ingredients: ((json['ingredients'] ?? const []) as List).map((e) => Ingredient.fromJson(e as Map<String, dynamic>)).toList(),
        steps: ((json['steps'] ?? const []) as List).map((e) => RecipeStep.fromJson(e as Map<String, dynamic>)).toList(),
        sourceUrl: json['sourceUrl'] as String?,
        imported: (json['imported'] ?? false) as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title.toJson(),
        'minutes': minutes,
        'servings': servings,
        'tags': tags,
        'color': color,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps.map((e) => e.toJson()).toList(),
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
        'imported': imported,
      };
}

/// A canonical ingredient used by the pantry and the shopping list.
class PantryItem {
  const PantryItem({required this.id, required this.name, this.staple = false, this.group = 'other'});

  final String id;
  final Bilingual name;

  /// Staples (salt, oil, water...) are assumed to be at home.
  final bool staple;
  final String group;

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
        id: json['id'] as String,
        name: Bilingual(en: json['en'] as String, ar: json['ar'] as String),
        staple: (json['staple'] ?? false) as bool,
        group: (json['group'] ?? 'other') as String,
      );
}

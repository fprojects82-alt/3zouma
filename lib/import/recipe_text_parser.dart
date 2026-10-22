import '../core/text_normalize.dart';
import '../cooking/duration_parser.dart';
import '../models/recipe.dart';

/// Result of reading a pasted recipe.
class ParsedRecipe {
  const ParsedRecipe({required this.title, required this.ingredients, required this.steps});

  final String title;
  final List<String> ingredients;
  final List<String> steps;

  bool get isEmpty => steps.isEmpty;

  int get timerCount => steps.where((s) => DurationParser.parse(s) != null).length;

  /// Turns the parsed text into a recipe stored in the language it was written in.
  Recipe toRecipe({required String id, required bool arabic, String? sourceUrl, String? titleOverride}) {
    Bilingual b(String s) => arabic ? Bilingual(en: '', ar: s) : Bilingual(en: s, ar: '');
    final name = (titleOverride ?? title).trim();
    final totalSeconds = steps.fold<int>(0, (sum, s) => sum + (DurationParser.parse(s)?.inSeconds ?? 0));
    return Recipe(
      id: id,
      title: b(name.isEmpty ? (arabic ? 'وصفتي' : 'My recipe') : name),
      minutes: totalSeconds == 0 ? 0 : (totalSeconds / 60).ceil() + steps.length * 2,
      servings: 2,
      ingredients: ingredients.map((i) => Ingredient(id: '', name: b(i))).toList(),
      steps: steps.map((s) => RecipeStep(text: b(s))).toList(),
      sourceUrl: sourceUrl,
      imported: true,
      color: 0xFF9C8670,
    );
  }
}

/// Splits recipe text copied from WhatsApp, Facebook, a caption or notes into
/// a title, ingredients and steps. Understands English and Arabic headings,
/// numbered and bulleted lists, and steps written as one paragraph.
class RecipeTextParser {
  static final _ingredientHeads = ['ingredients', 'you will need', 'you need', 'المكونات', 'مكونات', 'المقادير', 'مقادير', 'هنحتاج', 'هتحتاجي'];
  static final _stepHeads = ['steps', 'method', 'directions', 'instructions', 'how to make', 'preparation', 'الطريقه', 'طريقه العمل', 'طريقه التحضير', 'الخطوات', 'التحضير', 'طريقه'];

  static ParsedRecipe parse(String raw) {
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !_isHashtagLine(l))
        .toList();
    if (lines.isEmpty) return const ParsedRecipe(title: '', ingredients: [], steps: []);

    String title = '';
    final ingredients = <String>[];
    final steps = <String>[];
    var section = _Section.unknown;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final head = _headingOf(line);
      if (head != null) {
        section = head;
        // "Ingredients: rice, lentils" keeps what follows the colon.
        final rest = _afterColon(line);
        if (rest.isNotEmpty) {
          if (head == _Section.ingredients) {
            ingredients.addAll(_splitInline(rest));
          } else {
            steps.addAll(_splitSentences(rest));
          }
        }
        continue;
      }
      if (title.isEmpty && section == _Section.unknown && i == 0 && !_looksLikeListItem(line) && line.length <= 60) {
        title = _stripMarker(line);
        continue;
      }
      final item = _stripMarker(line);
      if (item.isEmpty) continue;
      switch (section) {
        case _Section.ingredients:
          ingredients.add(item);
        case _Section.steps:
          steps.addAll(_splitSentences(item, keepWhole: _looksLikeListItem(line)));
        case _Section.unknown:
          // No headings: short quantity lines are ingredients, the rest are steps.
          if (_looksLikeIngredient(item)) {
            ingredients.add(item);
          } else {
            steps.addAll(_splitSentences(item, keepWhole: _looksLikeListItem(line)));
          }
      }
    }
    return ParsedRecipe(title: title, ingredients: ingredients, steps: steps.where((s) => s.length > 2).toList());
  }

  static bool _isHashtagLine(String l) => RegExp(r'^(#\S+\s*)+$').hasMatch(l);

  static _Section? _headingOf(String line) {
    final n = normalizeText(line.replaceAll(RegExp(r'[:：]+.*$'), ''));
    if (n.length > 30) return null;
    for (final h in _ingredientHeads) {
      if (n == normalizeText(h)) return _Section.ingredients;
    }
    for (final h in _stepHeads) {
      if (n == normalizeText(h)) return _Section.steps;
    }
    return null;
  }

  static String _afterColon(String line) {
    final i = line.indexOf(RegExp(r'[:：]'));
    return i < 0 ? '' : line.substring(i + 1).trim();
  }

  static final _marker = RegExp(r'^\s*(?:[-*•·▪◦]+|\(?[0-9٠-٩]+[).\-:]|[0-9٠-٩]+\s*[-.)]|step\s*[0-9٠-٩]+\s*[:.)-]?|الخطوه\s*[0-9٠-٩]+\s*[:.)-]?|✅|✔️?|👉)\s*', caseSensitive: false);

  static bool _looksLikeListItem(String line) => _marker.hasMatch(line);

  static String _stripMarker(String line) => line.replaceFirst(_marker, '').trim();

  static bool _looksLikeIngredient(String item) {
    if (item.length > 60) return false;
    final n = normalizeText(item);
    if (DurationParser.parse(item) != null) return false;
    final startsWithQty = RegExp(r'^(\d+|نص|ربع|half|a |an |one |two )').hasMatch(n);
    const units = ['cup', 'tbsp', 'tsp', 'g ', 'kg', 'gram', 'clove', 'pinch', 'كوب', 'معلق', 'جرام', 'كيلو', 'فص', 'رشه', 'ملعق'];
    final hasUnit = units.any(n.contains);
    final verbs = ['add', 'mix', 'stir', 'cook', 'boil', 'fry', 'bake', 'put', 'heat', 'ضيف', 'قلب', 'حط', 'اسلق', 'حمر', 'سخن', 'اخلط', 'سيب'];
    final hasVerb = verbs.any((v) => n.startsWith(v) || n.contains(' $v'));
    return (startsWithQty || hasUnit) && !hasVerb;
  }

  static List<String> _splitInline(String text) =>
      text.split(RegExp(r'[,،;؛]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// A long paragraph becomes one step per sentence.
  static List<String> _splitSentences(String text, {bool keepWhole = false}) {
    if (keepWhole || text.length < 90) return [text];
    final parts = text.split(RegExp(r'(?<=[.!؟?])\s+|\s+(?:then|ثم|وبعدين)\s+', caseSensitive: false));
    return parts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}

enum _Section { unknown, ingredients, steps }

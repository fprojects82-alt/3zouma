import 'package:flutter_test/flutter_test.dart';
import 'package:ozouma/import/recipe_text_parser.dart';

void main() {
  test('English recipe with headings and numbered steps', () {
    const text = '''
Easy shakshuka

Ingredients:
- 4 eggs
- 3 tomatoes, chopped
- 1 onion

Method
1. Fry the onion for 5 minutes.
2. Add the tomatoes and simmer 8 minutes.
3. Crack in the eggs, cover and cook 5 minutes.
#shakshuka #breakfast
''';
    final r = RecipeTextParser.parse(text);
    expect(r.title, 'Easy shakshuka');
    expect(r.ingredients, ['4 eggs', '3 tomatoes, chopped', '1 onion']);
    expect(r.steps.length, 3);
    expect(r.steps.first, 'Fry the onion for 5 minutes.');
    expect(r.timerCount, 3);
  });

  test('Arabic recipe from WhatsApp', () {
    const text = '''
مكرونة بالبشاميل
المكونات:
٢ كوباية مكرونة
نص كيلو لحمة مفرومة
الطريقة:
١- اسلقي المكرونة ١٠ دقايق
٢- شوحي اللحمة مع البصل
٣- ادخليها الفرن نص ساعة
''';
    final r = RecipeTextParser.parse(text);
    expect(r.title, 'مكرونة بالبشاميل');
    expect(r.ingredients.length, 2);
    expect(r.steps.length, 3);
    expect(r.timerCount, 2);
  });

  test('ingredients on one line after the heading', () {
    final r = RecipeTextParser.parse('Ingredients: rice, lentils, onions\nSteps:\nCook everything for 20 minutes.');
    expect(r.ingredients, ['rice', 'lentils', 'onions']);
    expect(r.steps, ['Cook everything for 20 minutes.']);
  });

  test('empty text gives an empty result', () {
    expect(RecipeTextParser.parse('   ').isEmpty, isTrue);
  });

  test('saving keeps the language and the source link', () {
    final parsed = RecipeTextParser.parse('Toast\nSteps:\nToast the bread for 2 minutes.');
    final recipe = parsed.toRecipe(id: 'x', arabic: false, sourceUrl: 'https://example.com/r');
    expect(recipe.title.en, 'Toast');
    expect(recipe.imported, isTrue);
    expect(recipe.sourceUrl, 'https://example.com/r');
    expect(recipe.steps.first.timer(false), const Duration(minutes: 2));
  });
}

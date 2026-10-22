import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../models/recipe.dart';
import '../widgets/common.dart';
import '../widgets/format.dart';
import 'cooking_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  int? _servings;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final recipe = app.recipes.byId(widget.recipeId);
    if (recipe == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(context.tr('no_results'))));
    }
    final servings = _servings ?? recipe.servings;
    final factor = recipe.servings == 0 ? 1.0 : servings / recipe.servings;
    final arabic = context.isArabic;
    final saved = app.recipes.isSaved(recipe.id);

    return Scaffold(
      backgroundColor: OzColors.linen,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Color(recipe.color),
            foregroundColor: Colors.white,
            actions: [
              if (recipe.imported)
                IconButton(
                  tooltip: context.tr('delete'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await app.recipes.deleteImported(recipe.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                )
              else
                IconButton(
                  tooltip: saved ? context.tr('saved_recipe') : context.tr('save_recipe'),
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () => app.recipes.toggleSaved(recipe.id),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: DishPhoto(recipe: recipe, radius: 0, showName: false),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList.list(children: [
              Text(context.local(recipe.title), style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (recipe.minutes > 0) _Meta(icon: Icons.schedule, text: context.minutes(recipe.minutes)),
                  _Meta(icon: Icons.format_list_numbered, text: context.trf('steps_count', {'n': context.fmt(recipe.steps.length)})),
                  if (recipe.timerCount(arabic) > 0)
                    _Meta(icon: Icons.timer_outlined, text: context.trf('timers_count', {'n': context.fmt(recipe.timerCount(arabic))})),
                ],
              ),
              if (recipe.sourceUrl != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => launchUrl(Uri.parse(recipe.sourceUrl!), mode: LaunchMode.externalApplication),
                  child: Row(children: [
                    const Icon(Icons.link, size: 18, color: OzColors.plum),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${context.tr('source')}: ${recipe.sourceUrl}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: OzColors.plum)),
                    ),
                  ]),
                ),
              ],
              SectionTitle(
                context.tr('ingredients'),
                action: recipe.ingredients.any((i) => i.qty != null)
                    ? _ServingsStepper(
                        value: servings,
                        onChanged: (v) => setState(() => _servings = v),
                      )
                    : null,
              ),
              for (final ing in recipe.ingredients) _IngredientRow(ing: ing, factor: factor),
              SectionTitle(context.tr('steps')),
              for (var i = 0; i < recipe.steps.length; i++) _StepRow(index: i, step: recipe.steps[i]),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(color: OzColors.linen, border: Border(top: BorderSide(color: OzColors.line))),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final n = await app.kitchen.addRecipe(recipe, amountOf: (i) => ingredientAmount(context, i, factor: factor));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.trf('added_to_list', {'n': context.fmt(n)}))),
                    );
                  },
                  child: Text(context.tr('get_ingredients')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: recipe.steps.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CookingScreen(recipe: recipe, factor: factor)),
                          ),
                  child: Text(context.tr('start_cooking')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: OzColors.linenDeep, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: OzColors.inkSoft),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton.outlined(
        tooltip: '-',
        onPressed: value > 1 ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove, size: 18),
      ),
      SizedBox(
        width: 70,
        child: Text(
          context.trf('serves', {'n': context.fmt(value)}),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      IconButton.outlined(
        tooltip: '+',
        onPressed: value < 20 ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add, size: 18),
      ),
    ]);
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ing, required this.factor});

  final Ingredient ing;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final have = ing.id.isNotEmpty && context.app.kitchen.has(ing.id);
    final amount = ingredientAmount(context, ing, factor: factor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(have ? Icons.check_circle : Icons.circle_outlined, size: 20, color: have ? OzColors.plum : OzColors.line),
          const SizedBox(width: 12),
          Expanded(child: Text(context.local(ing.name), style: const TextStyle(fontSize: 16))),
          if (amount.isNotEmpty) Text(amount, style: const TextStyle(fontSize: 15, color: OzColors.inkSoft, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.step});

  final int index;
  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    final timer = step.timer(context.isArabic);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(context.fmt(index + 1), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: OzColors.plum)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.local(step.text), style: const TextStyle(fontSize: 16, height: 1.5)),
                if (timer != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: OzColors.saffronSoft, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      context.trf('timer_in_step', {'t': context.clock(timer)}),
                      style: const TextStyle(color: Color(0xFF6E4A00), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

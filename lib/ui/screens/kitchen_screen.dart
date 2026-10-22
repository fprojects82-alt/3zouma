import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../data/settings.dart';
import '../../data/stores.dart';
import '../widgets/common.dart';
import 'recipe_screen.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(context.tr('kitchen_title'), style: Theme.of(context).textTheme.headlineLarge),
            ),
            TabBar(
              labelColor: OzColors.plum,
              unselectedLabelColor: OzColors.inkSoft,
              indicatorColor: OzColors.plum,
              tabs: [Tab(text: context.tr('pantry')), Tab(text: context.tr('shopping_list'))],
            ),
            const Expanded(child: TabBarView(children: [_PantryTab(), _ShoppingTab()])),
          ],
        ),
      ),
    );
  }
}

class _PantryTab extends StatelessWidget {
  const _PantryTab();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final items = app.recipes.pantryItems.where((i) => !i.staple).toList();
    final matches = app.kitchen.match(app.recipes.all, app.recipes.pantryItems);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(context.tr('pantry_hint'), style: const TextStyle(color: OzColors.inkSoft)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              FilterChip(
                label: Text(context.local(item.name)),
                selected: app.kitchen.has(item.id),
                showCheckmark: false,
                labelStyle: TextStyle(color: app.kitchen.has(item.id) ? OzColors.linen : OzColors.ink, fontWeight: FontWeight.w500),
                onSelected: (_) => app.kitchen.togglePantry(item.id),
              ),
          ],
        ),
        SectionTitle(context.tr('you_can_make')),
        if (matches.isEmpty)
          Text(context.tr('cook_with_sub'), style: const TextStyle(color: OzColors.inkSoft))
        else
          for (final m in matches)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                padding: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecipeScreen(recipeId: m.recipe.id))),
                  child: Row(
                    children: [
                      SizedBox(width: 64, height: 64, child: DishPhoto(recipe: m.recipe, radius: 16, showName: false)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.local(m.recipe.title), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              m.missing.isEmpty
                                  ? context.tr('have_all')
                                  : '${context.trf('missing_n', {'n': context.fmt(m.missing.length)})}: ${m.missing.map((id) {
                                      final p = app.recipes.pantryItem(id);
                                      return p == null ? id : context.local(p.name);
                                    }).join('، ')}',
                              style: TextStyle(color: m.missing.isEmpty ? OzColors.plum : OzColors.inkSoft, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _ShoppingTab extends StatelessWidget {
  const _ShoppingTab();

  Future<void> _openStore(BuildContext context, GroceryStore store) async {
    final app = context.app;
    final open = app.kitchen.shopping.where((s) => !s.checked).toList();
    final lines = open.map((s) => '- ${context.local(s.name)}${s.amount.isEmpty ? '' : ' (${s.amount})'}').join('\n');
    final query = StoreLinks.supportsSearch(store) && open.isNotEmpty ? context.local(open.first.name) : null;
    await Clipboard.setData(ClipboardData(text: lines));
    await launchUrl(StoreLinks.open(store, query: query), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final list = app.kitchen.shopping;
    final store = app.settings.store;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(context.tr('shopping_empty'), textAlign: TextAlign.center, style: const TextStyle(color: OzColors.inkSoft)),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            children: [
              for (final item in list)
                CheckboxListTile(
                  value: item.checked,
                  onChanged: (_) => app.kitchen.toggleChecked(item),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: OzColors.plum,
                  title: Text(
                    context.local(item.name),
                    style: TextStyle(decoration: item.checked ? TextDecoration.lineThrough : null),
                  ),
                  subtitle: item.amount.isEmpty ? null : Text(item.amount),
                  secondary: IconButton(
                    tooltip: context.tr('delete'),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => app.kitchen.remove(item),
                  ),
                ),
              if (list.any((s) => s.checked))
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(onPressed: app.kitchen.clearChecked, child: Text(context.tr('clear_checked'))),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(color: OzColors.linen, border: Border(top: BorderSide(color: OzColors.line))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<GroceryStore>(
                segments: [
                  for (final s in GroceryStore.values) ButtonSegment(value: s, label: Text(StoreLinks.name(s, context.isArabic))),
                ],
                selected: {store},
                showSelectedIcon: false,
                onSelectionChanged: (v) => app.settings.setStore(v.first),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => _openStore(context, store),
                icon: const Icon(Icons.shopping_basket_outlined),
                label: Text(context.trf('open_in', {'store': StoreLinks.name(store, context.isArabic)})),
              ),
              const SizedBox(height: 6),
              Text(context.tr('store_note'), textAlign: TextAlign.center, style: const TextStyle(color: OzColors.inkSoft, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

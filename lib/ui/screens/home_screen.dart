import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';
import 'recipe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenKitchen});

  final VoidCallback onOpenKitchen;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String? _tag;

  static const _tags = [
    (null, 'cat_all'),
    ('egyptian', 'cat_egyptian'),
    ('quick', 'cat_quick'),
    ('vegetarian', 'cat_vegetarian'),
    ('dessert', 'cat_dessert'),
    ('ramadan', 'cat_ramadan'),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = context.app.recipes.search(_search.text, tag: _tag);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList.list(children: [
              const Align(alignment: AlignmentDirectional.centerStart, child: OzLogo(height: 44)),
              const SizedBox(height: 20),
              Text(context.tr('greeting'), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.tr('search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.tr('cancel'),
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tags.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final (tag, label) = _tags[i];
                    final selected = _tag == tag;
                    return ChoiceChip(
                      label: Text(context.tr(label)),
                      selected: selected,
                      showCheckmark: false,
                      labelStyle: TextStyle(color: selected ? OzColors.linen : OzColors.ink, fontWeight: FontWeight.w500),
                      onSelected: (_) => setState(() => _tag = tag),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _PantryBanner(onTap: widget.onOpenKitchen),
              const SizedBox(height: 8),
            ]),
          ),
          if (results.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(32),
              sliver: SliverToBoxAdapter(
                child: Text(context.tr('no_results'), textAlign: TextAlign.center, style: const TextStyle(color: OzColors.inkSoft)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                itemCount: results.length,
                itemBuilder: (context, i) => RecipeCard(
                  recipe: results[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RecipeScreen(recipeId: results[i].id)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PantryBanner extends StatelessWidget {
  const _PantryBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OzColors.plum,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: OzColors.saffron, shape: BoxShape.circle),
                child: const Icon(Icons.kitchen, color: OzColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('cook_with_what_i_have'),
                        style: const TextStyle(color: OzColors.linen, fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(context.tr('cook_with_sub'), style: TextStyle(color: OzColors.linen.withValues(alpha: 0.8), fontSize: 13)),
                  ],
                ),
              ),
              Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: OzColors.linen),
            ],
          ),
        ),
      ),
    );
  }
}

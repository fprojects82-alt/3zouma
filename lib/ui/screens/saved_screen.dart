import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';
import 'recipe_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final saved = app.recipes.saved;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(context.tr('saved_title'), style: Theme.of(context).textTheme.headlineLarge),
            ),
          ),
          if (saved.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.bookmark_border, size: 48, color: OzColors.inkSoft),
                    const SizedBox(height: 12),
                    Text(context.tr('saved_empty'), textAlign: TextAlign.center, style: const TextStyle(color: OzColors.inkSoft)),
                  ]),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.78,
                ),
                itemCount: saved.length,
                itemBuilder: (context, i) {
                  final r = saved[i];
                  final cooked = app.recipes.cookedCount(r.id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RecipeCard(
                          recipe: r,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecipeScreen(recipeId: r.id))),
                        ),
                      ),
                      Text(
                        r.imported
                            ? context.tr('from_you')
                            : cooked > 0
                                ? context.trf('cooked_times', {'n': context.fmt(cooked)})
                                : '',
                        style: const TextStyle(color: OzColors.plum, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

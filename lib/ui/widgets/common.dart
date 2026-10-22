import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../models/recipe.dart';

/// The Ozouma wordmark. [onDark] picks the version with light letters.
class OzLogo extends StatelessWidget {
  const OzLogo({super.key, this.height = 40, this.onDark = false});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onDark ? 'assets/brand/logo_dark.png' : 'assets/brand/logo_light.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: context.tr('app_name'),
      errorBuilder: (context, error, stack) => Text(
        context.tr('app_name'),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: onDark ? OzColors.linen : OzColors.plum),
      ),
    );
  }
}

/// Stand-in for food photography: the dish colour with its name.
class DishPhoto extends StatelessWidget {
  const DishPhoto({super.key, required this.recipe, this.height, this.radius = 24, this.showName = true});

  final Recipe recipe;
  final double? height;
  final double radius;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final c = Color(recipe.color);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(c, Colors.white, 0.12)!, Color.lerp(c, Colors.black, 0.28)!],
        ),
      ),
      alignment: AlignmentDirectional.bottomStart,
      padding: const EdgeInsets.all(14),
      child: showName
          ? Text(
              context.local(recipe.title),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.4),
            )
          : null,
    );
  }
}

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap, this.trailing});

  final Recipe recipe;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = recipe.timerCount(context.isArabic);
    final meta = [
      if (recipe.minutes > 0) context.minutes(recipe.minutes),
      context.trf('steps_count', {'n': context.fmt(recipe.steps.length)}),
      if (t > 0) context.trf('timers_count', {'n': context.fmt(t)}),
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 4 / 3, child: DishPhoto(recipe: recipe, showName: false)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.local(recipe.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 2),
          Text(meta, style: const TextStyle(color: OzColors.inkSoft, fontSize: 13)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.headlineSmall)),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// A rounded panel on the linen background.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color = OzColors.linen});

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Material (not a coloured box) so list tiles inside keep their ink.
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

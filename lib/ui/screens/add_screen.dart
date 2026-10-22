import 'package:flutter/material.dart';

import '../../cooking/duration_parser.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../import/recipe_text_parser.dart';
import '../widgets/common.dart';

/// Import a recipe from pasted text, keeping the link as its source.
class AddScreen extends StatefulWidget {
  const AddScreen({super.key, required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _link = TextEditingController();
  final _text = TextEditingController();
  final _title = TextEditingController();
  ParsedRecipe? _parsed;
  bool _triedEmpty = false;

  @override
  void dispose() {
    _link.dispose();
    _text.dispose();
    _title.dispose();
    super.dispose();
  }

  bool get _textIsArabic {
    final letters = RegExp(r'[؀-ۿ]').allMatches(_text.text).length;
    final latin = RegExp('[A-Za-z]').allMatches(_text.text).length;
    return letters >= latin;
  }

  void _read() {
    FocusScope.of(context).unfocus();
    final parsed = RecipeTextParser.parse(_text.text);
    setState(() {
      _parsed = parsed.isEmpty ? null : parsed;
      _triedEmpty = parsed.isEmpty;
      _title.text = parsed.title;
    });
  }

  Future<void> _save() async {
    final parsed = _parsed;
    if (parsed == null) return;
    final app = context.app;
    final messenger = ScaffoldMessenger.of(context);
    final message = context.tr('recipe_saved');
    final link = _link.text.trim();
    final recipe = parsed.toRecipe(
      id: 'import_${DateTime.now().millisecondsSinceEpoch}',
      arabic: _textIsArabic,
      sourceUrl: link.isEmpty ? null : link,
      titleOverride: _title.text,
    );
    await app.recipes.addImported(recipe);
    messenger.showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      _parsed = null;
      _text.clear();
      _link.clear();
      _title.clear();
    });
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(context.tr('add_title'), style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 20),
          Text(context.tr('add_link'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _link,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: context.tr('add_link_hint'), prefixIcon: const Icon(Icons.link)),
          ),
          if (_link.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Panel(
              color: OzColors.plumTint,
              padding: const EdgeInsets.all(14),
              child: Text(context.tr('link_saved_note'), style: const TextStyle(color: OzColors.plum, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 20),
          Text(context.tr('add_text'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            minLines: 6,
            maxLines: 14,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: context.tr('add_text_hint'), alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _text.text.trim().isEmpty ? null : _read,
            child: Text(context.tr('read_recipe')),
          ),
          if (_triedEmpty) ...[
            const SizedBox(height: 12),
            Text(context.tr('nothing_found'), style: const TextStyle(color: OzColors.alert)),
          ],
          if (parsed != null) ..._review(context, parsed),
        ],
      ),
    );
  }

  List<Widget> _review(BuildContext context, ParsedRecipe parsed) {
    return [
      SectionTitle(context.tr('review_recipe')),
      Text(
        context.trf('found_summary', {
          'i': context.fmt(parsed.ingredients.length),
          's': context.fmt(parsed.steps.length),
          't': context.fmt(parsed.timerCount),
        }),
        style: const TextStyle(color: OzColors.inkSoft),
      ),
      const SizedBox(height: 12),
      TextField(controller: _title, decoration: InputDecoration(labelText: context.tr('title_label'))),
      if (parsed.ingredients.isNotEmpty) ...[
        SectionTitle(context.tr('ingredients')),
        for (final i in parsed.ingredients)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.circle, size: 6, color: OzColors.plum),
              const SizedBox(width: 10),
              Expanded(child: Text(i)),
            ]),
          ),
      ],
      SectionTitle(context.tr('steps')),
      for (var n = 0; n < parsed.steps.length; n++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 28, child: Text(context.fmt(n + 1), style: const TextStyle(color: OzColors.plum, fontWeight: FontWeight.w700))),
            Expanded(child: Text(parsed.steps[n], style: const TextStyle(height: 1.45))),
            if (DurationParser.parse(parsed.steps[n]) case final d?)
              Container(
                margin: const EdgeInsetsDirectional.only(start: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: OzColors.saffronSoft, borderRadius: BorderRadius.circular(999)),
                child: Text(context.clock(d), style: const TextStyle(color: Color(0xFF6E4A00), fontWeight: FontWeight.w600, fontSize: 12)),
              ),
          ]),
        ),
      const SizedBox(height: 8),
      Text(context.tr('timers_are_guesses'), style: const TextStyle(color: OzColors.inkSoft, fontSize: 12)),
      const SizedBox(height: 16),
      FilledButton(onPressed: _save, child: Text(context.tr('save'))),
    ];
  }
}

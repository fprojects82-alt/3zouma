import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';

/// First launch: pick Arabic or English. Sets screen direction and the
/// voice command language.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  bool _arabic = true;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(alignment: AlignmentDirectional.centerStart, child: OzLogo(height: 64)),
              const SizedBox(height: 36),
              Text(strings.t('choose_language'), style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              const Text('اختاري لغتك · Choose your language', style: TextStyle(color: OzColors.inkSoft)),
              const SizedBox(height: 24),
              _Option(
                selected: _arabic,
                title: strings.t('lang_ar_title'),
                subtitle: 'واجهة عربية وأوامر صوت بالمصري',
                onTap: () => setState(() => _arabic = true),
              ),
              const SizedBox(height: 12),
              _Option(
                selected: !_arabic,
                title: strings.t('lang_en_title'),
                subtitle: 'English screens and voice commands',
                onTap: () => setState(() => _arabic = false),
              ),
              const SizedBox(height: 16),
              Text(strings.t('lang_note'), style: const TextStyle(color: OzColors.inkSoft, fontSize: 13)),
              const Spacer(),
              FilledButton(
                onPressed: () => context.app.settings.setLanguage(_arabic),
                child: Text(_arabic ? 'متابعة' : 'Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.selected, required this.title, required this.subtitle, required this.onTap});

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : OzColors.linen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? OzColors.plum : OzColors.line, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? OzColors.plum : OzColors.inkSoft),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: OzColors.inkSoft, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../data/settings.dart';
import '../../data/stores.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.app.settings;
    final arabic = context.isArabic;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(context.tr('profile_title'), style: Theme.of(context).textTheme.headlineLarge),
          SectionTitle(context.tr('settings')),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: [
              _Row(
                title: context.tr('app_language'),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('عربي')),
                    ButtonSegment(value: false, label: Text('EN')),
                  ],
                  selected: {s.arabic},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => s.setLanguage(v.first),
                ),
              ),
              const Divider(color: OzColors.line),
              _Row(
                title: context.tr('voice_language'),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(context.tr('egyptian_arabic'))),
                    ButtonSegment(value: false, label: Text(context.tr('english'))),
                  ],
                  selected: {s.voiceArabic},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => s.setVoiceArabic(v.first),
                ),
              ),
              const Divider(color: OzColors.line),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: OzColors.plum,
                title: Text(context.tr('voice_control')),
                value: s.voiceOn,
                onChanged: s.setVoiceOn,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: OzColors.plum,
                title: Text(context.tr('read_aloud')),
                value: s.readAloud,
                onChanged: s.setReadAloud,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: OzColors.plum,
                title: Text(context.tr('eastern_numerals')),
                value: s.easternNumerals,
                onChanged: s.setEasternNumerals,
              ),
              const Divider(color: OzColors.line),
              _Row(
                title: context.tr('store'),
                child: DropdownButton<GroceryStore>(
                  value: s.store,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final st in GroceryStore.values) DropdownMenuItem(value: st, child: Text(StoreLinks.name(st, arabic))),
                  ],
                  onChanged: (v) {
                    if (v != null) s.setStore(v);
                  },
                ),
              ),
            ]),
          ),
          SectionTitle(context.tr('about')),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OzLogo(height: 40),
                const SizedBox(height: 12),
                Text(context.tr('about_body'), style: const TextStyle(height: 1.5, color: OzColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [Text(title, style: const TextStyle(fontSize: 16)), child],
      ),
    );
  }
}

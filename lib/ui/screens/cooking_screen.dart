import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../cooking/cooking_session.dart';
import '../../cooking/voice_commands.dart';
import '../../cooking/voice_controller.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
import '../../models/recipe.dart';
import '../widgets/format.dart';
import '../widgets/timer_ring.dart';

/// Hands-free cooking: one big step at a time, voice commands, timers that
/// start on their own, and a screen that stays on.
class CookingScreen extends StatefulWidget {
  const CookingScreen({super.key, required this.recipe, this.factor = 1, this.enableDeviceFeatures = true});

  final Recipe recipe;

  /// Servings multiplier chosen on the recipe page.
  final double factor;

  /// False in widget tests: no microphone, speech or wake lock.
  final bool enableDeviceFeatures;

  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  late final CookingSession _session;
  VoiceController? _voice;
  Speaker? _speaker;
  Timer? _alarmRepeat;
  bool _showIngredients = false;
  bool _started = false;
  int _lastSpokenIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final settings = context.app.settings;
    _session = CookingSession(recipe: widget.recipe, arabic: context.isArabic)
      ..onTimerDone = _onTimerDone
      ..addListener(_onSessionChange);
    _session.startTicking();
    if (widget.enableDeviceFeatures) {
      WakelockPlus.enable().catchError((_) {});
      _speaker = Speaker()..init(arabic: settings.voiceArabic);
      if (settings.voiceOn) {
        _voice = VoiceController(onCommand: _onCommand)..addListener(() => setState(() {}));
        _voice!.start(arabic: settings.voiceArabic);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReadStep());
  }

  @override
  void dispose() {
    _alarmRepeat?.cancel();
    _session.removeListener(_onSessionChange);
    _session.dispose();
    _voice?.dispose();
    _speaker?.stop();
    if (widget.enableDeviceFeatures) WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  void _onSessionChange() {
    if (!mounted) return;
    setState(() {});
    if (_session.ringingTimers.isEmpty) {
      _alarmRepeat?.cancel();
      _alarmRepeat = null;
    }
    _maybeReadStep();
  }

  Future<void> _say(String text) async {
    final speaker = _speaker;
    if (speaker == null) return;
    await _voice?.suspend();
    await speaker.say(text);
    _voice?.resumeListening();
  }

  void _maybeReadStep() {
    if (!mounted || _session.finished) return;
    if (_session.index == _lastSpokenIndex) return;
    _lastSpokenIndex = _session.index;
    if (context.app.settings.readAloud) _say(_session.stepText);
  }

  void _onTimerDone(CookTimer timer) {
    _alert();
    _alarmRepeat?.cancel();
    _alarmRepeat = Timer.periodic(const Duration(seconds: 3), (_) => _alert());
    if (!mounted) return;
    _say(context.trf('timer_done', {'name': timer.label}));
  }

  void _alert() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  void _onCommand(CookCommand c) {
    if (!mounted) return;
    switch (c) {
      case CookCommand.next:
        if (_session.ringingTimers.isNotEmpty) _session.stopAlarm();
        _session.next();
      case CookCommand.back:
        _session.back();
      case CookCommand.repeat:
        _lastSpokenIndex = _session.index;
        _say(_session.stepText);
      case CookCommand.pause:
        _session.pause();
      case CookCommand.resume:
        _session.resume();
      case CookCommand.ingredients:
        setState(() => _showIngredients = !_showIngredients);
      case CookCommand.howLong:
        final t = _session.currentTimer ?? (_session.otherActiveTimers.isEmpty ? null : _session.otherActiveTimers.first);
        if (t != null) {
          _say(context.trf('time_left', {'t': _spokenDuration(t.remaining(_session.now))}));
        }
      case CookCommand.stopAlarm:
        _session.stopAlarm();
      case CookCommand.exit:
        Navigator.of(context).maybePop();
    }
  }

  String _spokenDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (context.isArabic) {
      if (m == 0) return '$s ثانية';
      return s == 0 ? '$m دقيقة' : '$m دقيقة و $s ثانية';
    }
    if (m == 0) return '$s seconds';
    return s == 0 ? '$m minutes' : '$m minutes $s seconds';
  }

  void _tapZone(TapUpDetails d, double width) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final x = d.localPosition.dx;
    // Forward is the bigger side in the reading direction.
    final forward = rtl ? x < width * 2 / 3 : x > width / 3;
    forward ? _session.next() : _session.back();
  }

  @override
  Widget build(BuildContext context) {
    if (_session.finished) return _FinishView(recipe: widget.recipe, onBack: _session.back);
    final color = Color(widget.recipe.color);
    return Scaffold(
      backgroundColor: OzColors.ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(color, Colors.black, 0.15)!, Color.lerp(color, Colors.black, 0.6)!],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _tapZone(d, box.maxWidth),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(session: _session, voice: _voice, onHelp: _showCommands),
                _ProgressDots(count: _session.stepCount, index: _session.index),
                if (_session.ringingTimers.isNotEmpty) _RingingBanner(session: _session),
                if (_session.otherActiveTimers.isNotEmpty) _OtherTimers(session: _session),
                const Spacer(),
                _StepCard(
                  session: _session,
                  onNext: _session.next,
                  onBack: _session.back,
                  onToggleTimer: () {
                    final t = _session.currentTimer;
                    if (t != null && t.running) {
                      _session.pause();
                    } else {
                      _session.resume();
                    }
                  },
                  onIngredients: () => setState(() => _showIngredients = !_showIngredients),
                ),
              ],
            ),
          ),
          if (_showIngredients)
            _IngredientsOverlay(
              recipe: widget.recipe,
              factor: widget.factor,
              onClose: () => setState(() => _showIngredients = false),
            ),
        ],
      ),
    );
  }

  void _showCommands() {
    final items = [
      ('cmd_next', 'اللي بعده · next'),
      ('cmd_back', 'ارجع · back'),
      ('cmd_repeat', 'تاني · repeat'),
      ('cmd_pause', 'استنى / كمّل · pause / resume'),
      ('cmd_ingredients', 'المكونات · ingredients'),
      ('cmd_how_long', 'فاضل قد إيه · how long'),
      ('cmd_stop', 'خلاص · stop'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: OzColors.linen,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('commands_title'), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              for (final (key, example) in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(child: Text(context.tr(key), style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text(example, style: const TextStyle(color: OzColors.inkSoft)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.session, required this.voice, required this.onHelp});

  final CookingSession session;
  final VoiceController? voice;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final state = voice?.state ?? VoiceState.off;
    final listening = state == VoiceState.listening || state == VoiceState.starting;
    final label = switch (state) {
      VoiceState.listening || VoiceState.starting => context.tr('listening'),
      VoiceState.denied || VoiceState.unavailable => context.tr('tap_mode'),
      VoiceState.off => context.tr('mic_off'),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          _Pill(
            onTap: () => Navigator.of(context).maybePop(),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.close, size: 18, color: OzColors.linen),
              const SizedBox(width: 4),
              Text(context.tr('exit'), style: const TextStyle(color: OzColors.linen, fontWeight: FontWeight.w500)),
            ]),
          ),
          const Spacer(),
          _Pill(
            onTap: onHelp,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: listening ? OzColors.listening : OzColors.inkSoft,
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: OzColors.linen, fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              const Icon(Icons.help_outline, size: 18, color: OzColors.linen),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: child),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= index ? OzColors.linen : OzColors.linen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingingBanner extends StatelessWidget {
  const _RingingBanner({required this.session});

  final CookingSession session;

  @override
  Widget build(BuildContext context) {
    final t = session.ringingTimers.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: OzColors.alert,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: session.stopAlarm,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              TimerRing(label: context.fmt(t.stepIndex + 1), progress: 1, size: 44, alert: true, onDark: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.trf('timer_done', {'name': t.label}),
                      style: const TextStyle(color: OzColors.linen, fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(context.tr('say_stop'), style: TextStyle(color: OzColors.linen.withValues(alpha: 0.85), fontSize: 13)),
                ]),
              ),
              const Icon(Icons.notifications_off_outlined, color: OzColors.linen),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OtherTimers extends StatelessWidget {
  const _OtherTimers({required this.session});

  final CookingSession session;

  @override
  Widget build(BuildContext context) {
    final now = session.now;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in session.otherActiveTimers.where((t) => !t.ringing))
            Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                TimerRing(
                  label: context.fmt(t.stepIndex + 1),
                  progress: t.progress(now),
                  size: 30,
                  onDark: true,
                  alert: t.inLastTenth(now),
                ),
                const SizedBox(width: 8),
                Text('${t.label} · ${context.clock(t.remaining(now))}',
                    style: const TextStyle(color: OzColors.linen, fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.session,
    required this.onNext,
    required this.onBack,
    required this.onToggleTimer,
    required this.onIngredients,
  });

  final CookingSession session;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onToggleTimer;
  final VoidCallback onIngredients;

  @override
  Widget build(BuildContext context) {
    final now = session.now;
    final timer = session.currentTimer;
    final hasTimer = session.stepDuration != null;
    final stepNo = context.fmt(session.index + 1);
    final size = MediaQuery.sizeOf(context);
    final textSize = size.width < 360 ? 26.0 : 32.0;

    String? timerLine;
    if (session.countIn != null) {
      timerLine = context.trf('starting_in', {'n': context.fmt(session.countIn!)});
    } else if (timer != null && timer.paused) {
      timerLine = '${context.tr('paused')} · ${context.clock(timer.remaining(now))}';
    } else if (timer != null && !timer.finished) {
      timerLine = context.trf('time_left', {'t': context.clock(timer.remaining(now))});
    } else if (timer == null && hasTimer) {
      timerLine = context.clock(session.stepDuration!);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: OzColors.linen,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 12))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TimerRing(
                label: stepNo,
                progress: timer?.progress(now) ?? 0,
                size: 88,
                active: hasTimer,
                alert: timer?.inLastTenth(now) ?? false,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.trf('step_of', {'n': stepNo, 'total': context.fmt(session.stepCount)}),
                  style: const TextStyle(color: OzColors.inkSoft, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                tooltip: context.tr('ingredients'),
                onPressed: onIngredients,
                icon: const Icon(Icons.format_list_bulleted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: size.height * 0.32),
            child: SingleChildScrollView(
              child: Text(
                session.stepText,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: textSize, height: 1.25),
              ),
            ),
          ),
          if (timerLine != null) ...[
            const SizedBox(height: 14),
            Material(
              color: OzColors.linenDeep,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onToggleTimer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Icon(timer != null && timer.running ? Icons.pause_circle_outline : Icons.play_circle_outline, color: OzColors.plum),
                    const SizedBox(width: 10),
                    Expanded(child: Text(timerLine, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                  ]),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: session.isFirst ? null : onBack, child: Text(context.tr('back'))),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onNext,
                  child: Text(session.isLast ? context.tr('finish') : context.tr('next')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientsOverlay extends StatelessWidget {
  const _IngredientsOverlay({required this.recipe, required this.factor, required this.onClose});

  final Recipe recipe;
  final double factor;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: Colors.black54,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(22),
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
                  decoration: BoxDecoration(color: OzColors.linen, borderRadius: BorderRadius.circular(28)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(child: Text(context.tr('ingredients'), style: Theme.of(context).textTheme.headlineSmall)),
                        IconButton(tooltip: context.tr('done'), onPressed: onClose, icon: const Icon(Icons.close)),
                      ]),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final ing in recipe.ingredients)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                child: Row(children: [
                                  Expanded(child: Text(context.local(ing.name), style: const TextStyle(fontSize: 17))),
                                  Text(ingredientAmount(context, ing, factor: factor),
                                      style: const TextStyle(fontSize: 16, color: OzColors.inkSoft, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishView extends StatefulWidget {
  const _FinishView({required this.recipe, required this.onBack});

  final Recipe recipe;
  final VoidCallback onBack;

  @override
  State<_FinishView> createState() => _FinishViewState();
}

class _FinishViewState extends State<_FinishView> {
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OzColors.plum,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.undo, color: OzColors.linen),
                  label: Text(context.tr('back'), style: const TextStyle(color: OzColors.linen)),
                ),
              ),
              const Spacer(),
              const Center(child: TimerRing(label: '✓', progress: 1, size: 120, onDark: true)),
              const SizedBox(height: 24),
              Text(context.tr('all_done_title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: OzColors.linen)),
              const SizedBox(height: 8),
              Text(context.local(widget.recipe.title),
                  textAlign: TextAlign.center, style: TextStyle(color: OzColors.linen.withValues(alpha: 0.85), fontSize: 17)),
              const SizedBox(height: 28),
              Text(context.tr('all_done_sub'), textAlign: TextAlign.center, style: const TextStyle(color: OzColors.linen)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      tooltip: '$i',
                      iconSize: 36,
                      onPressed: () => setState(() => _stars = i),
                      icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: OzColors.saffron),
                    ),
                ],
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: OzColors.linen, foregroundColor: OzColors.plum),
                onPressed: () async {
                  final app = context.app;
                  final messenger = ScaffoldMessenger.of(context);
                  final message = context.tr('rate_saved');
                  final nav = Navigator.of(context);
                  await app.recipes.markCooked(widget.recipe.id);
                  messenger.showSnackBar(SnackBar(content: Text(message)));
                  nav.pop();
                },
                child: Text(context.tr('done')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

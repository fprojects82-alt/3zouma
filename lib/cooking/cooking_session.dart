import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/recipe.dart';

/// One running kitchen timer. Timers belong to the step that started them and
/// keep running when the cook moves on, so several can run at once.
class CookTimer {
  CookTimer({required this.stepIndex, required this.label, required this.total});

  final int stepIndex;
  final String label;
  final Duration total;

  DateTime? _endsAt;
  Duration? _pausedRemaining;
  bool ringing = false;
  bool finished = false;

  bool get running => _endsAt != null && !finished;
  bool get paused => _pausedRemaining != null && !finished;

  void start(DateTime now) {
    _endsAt = now.add(total);
    _pausedRemaining = null;
  }

  void pause(DateTime now) {
    if (!running) return;
    _pausedRemaining = remaining(now);
    _endsAt = null;
  }

  void resume(DateTime now) {
    if (!paused) return;
    _endsAt = now.add(_pausedRemaining!);
    _pausedRemaining = null;
  }

  Duration remaining(DateTime now) {
    if (finished) return Duration.zero;
    if (_pausedRemaining != null) return _pausedRemaining!;
    if (_endsAt == null) return total;
    final left = _endsAt!.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// 0 when just started, 1 when done. Drives the timer ring.
  double progress(DateTime now) {
    if (total.inMilliseconds == 0) return 1;
    final p = 1 - remaining(now).inMilliseconds / total.inMilliseconds;
    return p.clamp(0.0, 1.0);
  }

  /// The ring turns red in the last 10% of the time.
  bool inLastTenth(DateTime now) => running && progress(now) >= 0.9;
}

/// State of cooking mode: which step is shown, its count-in, and all timers.
///
/// Time comes from [clock] and moves forward with [tick], which the screen
/// calls every second. Tests drive both by hand.
class CookingSession extends ChangeNotifier {
  CookingSession({
    required this.recipe,
    required this.arabic,
    DateTime Function()? clock,
    this.countInSeconds = 3,
  }) : _clock = clock ?? DateTime.now {
    _prepareStep();
  }

  final Recipe recipe;
  final bool arabic;
  final int countInSeconds;
  final DateTime Function() _clock;

  int _index = 0;
  int? _countIn;
  bool _finished = false;
  final List<CookTimer> timers = [];
  Timer? _ticker;

  /// Called once when a timer reaches zero.
  void Function(CookTimer timer)? onTimerDone;

  DateTime get now => _clock();
  int get index => _index;
  int get stepCount => recipe.steps.length;
  bool get isFirst => _index == 0;
  bool get isLast => _index == stepCount - 1;
  bool get finished => _finished;
  RecipeStep get step => recipe.steps[_index];
  String get stepText => step.text.of(arabic);

  /// Seconds until this step's timer starts, or null.
  int? get countIn => _countIn;

  Duration? get stepDuration => step.timer(arabic);

  CookTimer? timerForStep(int i) {
    for (final t in timers) {
      if (t.stepIndex == i) return t;
    }
    return null;
  }

  CookTimer? get currentTimer => timerForStep(_index);

  List<CookTimer> get ringingTimers => timers.where((t) => t.ringing).toList();

  /// Timers from other steps that are still going, shown as small chips.
  List<CookTimer> get otherActiveTimers =>
      timers.where((t) => t.stepIndex != _index && (t.running || t.paused || t.ringing)).toList();

  void startTicking() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void next() {
    if (isLast) {
      _finished = true;
      _countIn = null;
      notifyListeners();
      return;
    }
    _index++;
    _prepareStep();
    notifyListeners();
  }

  void back() {
    if (_finished) {
      _finished = false;
    } else if (!isFirst) {
      _index--;
    }
    _prepareStep();
    notifyListeners();
  }

  void goTo(int i) {
    if (i < 0 || i >= stepCount) return;
    _index = i;
    _finished = false;
    _prepareStep();
    notifyListeners();
  }

  /// Pauses the current step's timer, or the count-in.
  void pause() {
    if (_countIn != null) {
      _countIn = null;
      notifyListeners();
      return;
    }
    final t = currentTimer ?? _latestRunning();
    t?.pause(now);
    notifyListeners();
  }

  /// Resumes a paused timer, or starts this step's timer straight away.
  void resume() {
    final t = currentTimer;
    if (t != null && t.paused) {
      t.resume(now);
    } else if (t == null && stepDuration != null) {
      _startStepTimer();
    } else {
      _latestPaused()?.resume(now);
    }
    _countIn = null;
    notifyListeners();
  }

  /// Silences every ringing timer.
  void stopAlarm() {
    for (final t in timers) {
      t.ringing = false;
    }
    notifyListeners();
  }

  /// Moves time forward by one tick: runs the count-in and finishes timers.
  void tick() {
    var changed = false;
    if (_countIn != null) {
      _countIn = _countIn! - 1;
      if (_countIn! <= 0) {
        _countIn = null;
        _startStepTimer();
      }
      changed = true;
    }
    final t = now;
    for (final timer in timers) {
      if (timer.running && timer.remaining(t) == Duration.zero) {
        timer.finished = true;
        timer.ringing = true;
        changed = true;
        onTimerDone?.call(timer);
      }
    }
    // Running timers change every second.
    if (timers.any((x) => x.running)) changed = true;
    if (changed) notifyListeners();
  }

  void _prepareStep() {
    _countIn = null;
    if (_finished) return;
    if (stepDuration != null && currentTimer == null) {
      _countIn = countInSeconds;
      if (countInSeconds <= 0) {
        _countIn = null;
        _startStepTimer();
      }
    }
  }

  void _startStepTimer() {
    final d = stepDuration;
    if (d == null || currentTimer != null) return;
    final label = step.timerLabel?.of(arabic) ?? '${_index + 1}';
    timers.add(CookTimer(stepIndex: _index, label: label, total: d)..start(now));
  }

  CookTimer? _latestRunning() {
    for (final t in timers.reversed) {
      if (t.running) return t;
    }
    return null;
  }

  CookTimer? _latestPaused() {
    for (final t in timers.reversed) {
      if (t.paused) return t;
    }
    return null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

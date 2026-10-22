import 'package:flutter_test/flutter_test.dart';
import 'package:ozouma/cooking/cooking_session.dart';
import 'package:ozouma/models/recipe.dart';

Recipe _recipe() => const Recipe(
      id: 't',
      title: Bilingual(en: 'Test', ar: 'تجربة'),
      minutes: 10,
      servings: 2,
      ingredients: [],
      steps: [
        RecipeStep(text: Bilingual(en: 'Boil the water for 2 minutes.', ar: 'اغلي المية دقيقتين.')),
        RecipeStep(text: Bilingual(en: 'Add the pasta.', ar: 'ضيفي المكرونة.')),
        RecipeStep(text: Bilingual(en: 'Cook for 1 minute.', ar: 'سيبيها دقيقة واحدة.'), timerSeconds: 60),
      ],
    );

void main() {
  late DateTime now;
  late CookingSession session;

  setUp(() {
    now = DateTime(2026, 10, 22, 12);
    session = CookingSession(recipe: _recipe(), arabic: false, clock: () => now);
  });

  tearDown(() => session.dispose());

  void advance(int seconds) {
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      session.tick();
    }
  }

  test('a step with a time counts in, then starts its timer', () {
    expect(session.countIn, 3);
    expect(session.currentTimer, isNull);
    advance(3);
    expect(session.countIn, isNull);
    expect(session.currentTimer, isNotNull);
    expect(session.currentTimer!.total, const Duration(minutes: 2));
  });

  test('timers keep running on the next steps and ring when done', () {
    final done = <CookTimer>[];
    session.onTimerDone = done.add;
    advance(3);
    session.next();
    expect(session.index, 1);
    expect(session.countIn, isNull, reason: 'step 2 has no time');
    expect(session.otherActiveTimers.length, 1);
    advance(120);
    expect(done.length, 1);
    expect(session.ringingTimers.length, 1);
    session.stopAlarm();
    expect(session.ringingTimers, isEmpty);
  });

  test('pause and resume hold the remaining time', () {
    advance(3);
    advance(30);
    session.pause();
    final left = session.currentTimer!.remaining(now);
    advance(50);
    expect(session.currentTimer!.remaining(now), left);
    session.resume();
    advance(10);
    expect(session.currentTimer!.remaining(now), left - const Duration(seconds: 10));
  });

  test('resume skips the count-in', () {
    session.resume();
    expect(session.countIn, isNull);
    expect(session.currentTimer, isNotNull);
  });

  test('next on the last step finishes, back returns', () {
    session.next();
    session.next();
    expect(session.isLast, isTrue);
    session.next();
    expect(session.finished, isTrue);
    session.back();
    expect(session.finished, isFalse);
    expect(session.index, 2);
  });

  test('ring turns red in the last tenth', () {
    session.goTo(2);
    advance(3);
    advance(53);
    expect(session.currentTimer!.inLastTenth(now), isFalse);
    advance(2);
    expect(session.currentTimer!.inLastTenth(now), isTrue);
  });
}

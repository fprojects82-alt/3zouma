import 'package:flutter_test/flutter_test.dart';
import 'package:ozouma/cooking/duration_parser.dart';

Duration? p(String s) => DurationParser.parse(s);

void main() {
  group('English', () {
    test('minutes, hours and seconds', () {
      expect(p('Simmer for 12 minutes.'), const Duration(minutes: 12));
      expect(p('Bake for 1 hour'), const Duration(hours: 1));
      expect(p('Rest 30 secs'), const Duration(seconds: 30));
      expect(p('Cook 20 mins, stirring'), const Duration(minutes: 20));
    });

    test('ranges use the lower number', () {
      expect(p('Fry for 10 to 15 minutes'), const Duration(minutes: 10));
      expect(p('Boil 8-10 minutes'), const Duration(minutes: 8));
    });

    test('words and fractions', () {
      expect(p('Leave it for half an hour'), const Duration(minutes: 30));
      expect(p('Stir for a minute'), const Duration(minutes: 1));
      expect(p('Cook for five minutes'), const Duration(minutes: 5));
      expect(p('Roast for an hour and a half'), const Duration(minutes: 90));
    });

    test('combined hours and minutes become one timer', () {
      expect(p('Bake for 1 hour and 15 minutes'), const Duration(minutes: 75));
    });

    test('temperatures and quantities are not timers', () {
      expect(p('Heat the oven to 180°C'), isNull);
      expect(p('Add 2 cups of water'), isNull);
      expect(p('Roast at 200°C for 20 minutes'), const Duration(minutes: 20));
    });
  });

  group('Arabic', () {
    test('Eastern and Western digits', () {
      expect(p('سيبيها تغلي ٢٠ دقيقة'), const Duration(minutes: 20));
      expect(p('اسلقي المكرونة 10 دقايق'), const Duration(minutes: 10));
      expect(p('في الفرن ساعتين'), const Duration(hours: 2));
      expect(p('سيبيه ٣٠ ثانية'), const Duration(seconds: 30));
    });

    test('Egyptian expressions', () {
      expect(p('خبزيها نص ساعة'), const Duration(minutes: 30));
      expect(p('سيبيها تشربه ربع ساعة'), const Duration(minutes: 15));
      expect(p('على نار هادية ساعة ونص'), const Duration(minutes: 90));
      expect(p('قلبي دقيقتين'), const Duration(minutes: 2));
      expect(p('سيبيها خمس دقايق'), const Duration(minutes: 5));
      expect(p('حوالي تلت ساعة'), const Duration(minutes: 20));
    });

    test('ranges and temperatures', () {
      expect(p('سيبيه من ١٠ ل ١٥ دقيقة'), const Duration(minutes: 10));
      expect(p('حمري الفراخ في الفرن على ٢٠٠ درجة ٢٠ دقيقة'), const Duration(minutes: 20));
      expect(p('سخني الفرن على ١٨٠ درجة'), isNull);
      expect(p('ضيفي ٣ كوبايات مية'), isNull);
    });
  });
}

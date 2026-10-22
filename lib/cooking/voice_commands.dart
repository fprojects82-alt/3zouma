import '../core/text_normalize.dart';

enum CookCommand { next, back, repeat, pause, resume, ingredients, howLong, stopAlarm, exit }

/// Turns what the cook said into a command. Works with English and with the
/// way people actually speak in an Egyptian kitchen ("اللي بعده", "استنى").
///
/// Phrases are matched on normalized text (see [normalizeText]), so the
/// Arabic below is written the normalized way: ة as ه, أ/إ/آ as ا.
class VoiceCommands {
  static const Map<CookCommand, List<String>> _phrases = {
    CookCommand.exit: [
      'exit cooking', 'stop cooking', 'close cooking',
      'اقفل الطبخ', 'اقفلي الطبخ', 'خروج',
    ],
    CookCommand.stopAlarm: [
      'stop', 'stop alarm', 'silence', 'quiet', 'ok', 'okay', 'got it',
      'خلاص', 'تمام', 'بس', 'اسكت', 'كفايه',
    ],
    CookCommand.howLong: [
      'how long', 'how much time', 'time left', 'how many minutes',
      'فاضل قد ايه', 'فاضل كام', 'فاضل اد ايه', 'باقي قد ايه', 'باقي كام', 'الوقت',
    ],
    CookCommand.ingredients: [
      'ingredients', 'what do i need', 'how much',
      'المكونات', 'مكونات', 'المقادير', 'مقادير',
    ],
    CookCommand.pause: [
      'pause', 'wait', 'hold on', 'hold', 'pause timer',
      'استني', 'استنا', 'وقف', 'اقف', 'لحظه', 'ثانيه واحده',
    ],
    CookCommand.resume: [
      'resume', 'continue', 'start timer', 'start the timer', 'go on',
      'كمل', 'كملي', 'ابدا', 'ابدئي', 'شغل', 'شغلي',
    ],
    CookCommand.repeat: [
      'repeat', 'again', 'say again', 'say that again', 'read', 'read it',
      'تاني', 'كرر', 'كرري', 'عيد', 'عيدي', 'اقري', 'قول تاني',
    ],
    CookCommand.back: [
      'back', 'go back', 'previous', 'last step', 'previous step',
      'ارجع', 'ارجعي', 'رجوع', 'اللي قبله', 'اللي قبلها', 'قبله', 'السابق', 'الخطوه اللي فاتت',
    ],
    CookCommand.next: [
      'next', 'next step', 'done', 'go ahead', 'forward', 'okay next',
      'اللي بعده', 'اللي بعدها', 'بعده', 'بعدها', 'التالي', 'الخطوه اللي بعدها', 'الخطوه الجايه', 'يلا',
    ],
  };

  /// Checks phrases in a fixed priority so "how long" is not read as "long",
  /// and "next step" is not caught by "step". Returns null when nothing matched.
  static CookCommand? parse(String heard) {
    final text = ' ${normalizeText(heard)} ';
    if (text.trim().isEmpty) return null;
    CookCommand? best;
    var bestLen = 0;
    // The longest matching phrase wins; ties keep the order of [_phrases].
    _phrases.forEach((command, phrases) {
      for (final p in phrases) {
        final phrase = ' ${normalizeText(p)} ';
        if (text.contains(phrase) && phrase.length > bestLen) {
          best = command;
          bestLen = phrase.length;
        }
      }
    });
    return best;
  }
}

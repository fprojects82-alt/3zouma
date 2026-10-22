import '../core/text_normalize.dart';

/// A duration found inside a piece of text.
class DurationHit {
  const DurationHit(this.start, this.end, this.seconds);

  final int start;
  final int end;
  final int seconds;

  Duration get duration => Duration(seconds: seconds);
}

/// Finds cooking times in English and Egyptian Arabic step text, so that
/// "simmer for 12 minutes" or "سيبيها ربع ساعة" become timers on their own.
///
/// For a range like "10 to 15 minutes" the lower number is used; the cook can
/// always add time. "1 hour and 30 minutes" or "ساعة ونص" count as one timer.
class DurationParser {
  static Duration? parse(String text) {
    final hits = findAll(text);
    return hits.isEmpty ? null : hits.first.duration;
  }

  static List<DurationHit> findAll(String raw) {
    final text = normalizeText(raw);
    final found = <DurationHit>[];

    void add(RegExp re, int Function(Match m) seconds) {
      for (final m in re.allMatches(text)) {
        final s = seconds(m);
        if (s > 0) found.add(DurationHit(m.start, m.end, s));
      }
    }

    // English: numbers.
    add(
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:(?:-|to|or)\s*\d+(?:\.\d+)?\s*)?(hours?|hrs?|minutes?|mins?|seconds?|secs?)\b'),
      (m) => _toSeconds(double.parse(m.group(1)!), m.group(2)!),
    );
    // English: words.
    add(
      RegExp(r'\b(a couple of|a few|an|a|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|fifteen|twenty|twenty five|thirty|forty|forty five|sixty)\s+(?:(?:to|or)\s+[a-z]+\s+)?(hours?|minutes?|mins?|seconds?)\b'),
      (m) => _toSeconds(_enWords[m.group(1)!]!, m.group(2)!),
    );
    add(RegExp(r'\b(?:an hour and a half|one and a half hours?|1\.5 hours?)\b'), (_) => 5400);
    add(RegExp(r'\b(?:half an hour|half hour|a half hour)\b'), (_) => 1800);
    add(RegExp(r'\b(?:a quarter of an hour|quarter of an hour|quarter hour)\b'), (_) => 900);

    // Arabic: numbers, with optional range "10 ل 15" or "10-15".
    add(
      RegExp('(\\d+(?:\\.\\d+)?)\\s*(?:(?:-|ل|لل|الي|او)\\s*\\d+(?:\\.\\d+)?\\s*)?($_arUnits)'),
      (m) => _toSeconds(double.parse(m.group(1)!), m.group(2)!),
    );
    // Arabic: number words.
    add(
      RegExp('(?<![\\p{L}])(${_arWords.keys.join('|')})\\s+($_arUnits)', unicode: true),
      (m) => _toSeconds(_arWords[m.group(1)!]!, m.group(2)!),
    );
    // Arabic: fixed expressions (normalized spelling, ة is written ه).
    add(RegExp('ساعه\\s*ونص|ساعه\\s*ونصف'), (_) => 5400);
    add(RegExp('ساعه\\s*وربع'), (_) => 4500);
    add(RegExp('ساعه\\s*الا\\s*ربع'), (_) => 2700);
    add(RegExp('ساعه\\s*وتلت|ساعه\\s*وثلث'), (_) => 4800);
    add(RegExp('(?:نص|نصف)\\s*ساعه'), (_) => 1800);
    add(RegExp('ربع\\s*ساعه'), (_) => 900);
    add(RegExp('(?:تلت|ثلث)\\s*ساعه'), (_) => 1200);
    add(RegExp('دقيقتين|دقيقتان'), (_) => 120);
    add(RegExp('ساعتين|ساعتان'), (_) => 7200);
    add(RegExp('(?:لمده|مده|حوالي|قد)\\s+(ساعه|دقيقه)(?![\\p{L}])', unicode: true), (m) => m.group(1) == 'ساعه' ? 3600 : 60);

    if (found.isEmpty) return const [];

    // Keep the earliest, longest match where hits overlap.
    found.sort((a, b) => a.start != b.start ? a.start.compareTo(b.start) : (b.end - b.start).compareTo(a.end - a.start));
    final kept = <DurationHit>[];
    for (final h in found) {
      if (kept.isNotEmpty && h.start < kept.last.end) continue;
      kept.add(h);
    }

    // Join "1 hour and 30 minutes" or "ساعه و 10 دقايق" into one timer.
    final merged = <DurationHit>[];
    for (final h in kept) {
      if (merged.isNotEmpty) {
        final prev = merged.last;
        final gap = text.substring(prev.end, h.start).trim();
        if (gap.isEmpty || gap == 'and' || gap == 'و') {
          merged[merged.length - 1] = DurationHit(prev.start, h.end, prev.seconds + h.seconds);
          continue;
        }
      }
      merged.add(h);
    }
    return merged;
  }

  static const _arUnits = 'دقيقه|دقايق|دقائق|دقيقتين|ساعه|ساعات|ثانيه|ثواني|ثوان';

  static int _toSeconds(double n, String unit) {
    if (unit.startsWith('h') || unit.startsWith('ساع')) return (n * 3600).round();
    if (unit.startsWith('s') || unit.startsWith('ث')) return n.round();
    return (n * 60).round();
  }

  static const Map<String, double> _enWords = {
    'a couple of': 2,
    'a few': 3,
    'an': 1,
    'a': 1,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'fifteen': 15,
    'twenty': 20,
    'twenty five': 25,
    'thirty': 30,
    'forty': 40,
    'forty five': 45,
    'sixty': 60,
  };

  // Longer spellings first so "خمسه" wins over "خمس".
  static const Map<String, double> _arWords = {
    'خمسه واربعين': 45,
    'خمسه وعشرين': 25,
    'خمستاشر': 15,
    'خمسطاشر': 15,
    'خمسه عشر': 15,
    'عشرين': 20,
    'تلاتين': 30,
    'ثلاثين': 30,
    'اربعين': 40,
    'خمسين': 50,
    'واحده': 1,
    'واحد': 1,
    'اتنين': 2,
    'اثنين': 2,
    'تلاته': 3,
    'ثلاثه': 3,
    'تلات': 3,
    'ثلاث': 3,
    'اربعه': 4,
    'اربع': 4,
    'خمسه': 5,
    'خمس': 5,
    'سته': 6,
    'ست': 6,
    'سبعه': 7,
    'سبع': 7,
    'تمانيه': 8,
    'ثمانيه': 8,
    'تمن': 8,
    'تسعه': 9,
    'تسع': 9,
    'عشره': 10,
    'عشر': 10,
  };
}

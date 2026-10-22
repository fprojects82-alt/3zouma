/// Helpers for Eastern Arabic numerals (٠١٢٣٤٥٦٧٨٩).
class Numerals {
  static const _eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// Converts every Western digit in [text] to an Eastern Arabic digit.
  static String toEastern(String text) {
    final b = StringBuffer();
    for (final ch in text.runes) {
      if (ch >= 0x30 && ch <= 0x39) {
        b.write(_eastern[ch - 0x30]);
      } else {
        b.writeCharCode(ch);
      }
    }
    return b.toString();
  }

  /// Converts Eastern Arabic and Persian digits to Western digits.
  static String toWestern(String text) {
    final b = StringBuffer();
    for (final ch in text.runes) {
      if (ch >= 0x0660 && ch <= 0x0669) {
        b.writeCharCode(0x30 + ch - 0x0660);
      } else if (ch >= 0x06F0 && ch <= 0x06F9) {
        b.writeCharCode(0x30 + ch - 0x06F0);
      } else {
        b.writeCharCode(ch);
      }
    }
    return b.toString();
  }

  /// Formats a number for display, using Eastern digits when [eastern] is true.
  static String format(num value, {required bool eastern}) {
    String s;
    if (value == value.roundToDouble()) {
      s = value.round().toString();
    } else {
      s = value.toStringAsFixed(1);
      if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    }
    return eastern ? toEastern(s) : s;
  }

  /// m:ss or h:mm:ss for a timer.
  static String clock(Duration d, {required bool eastern}) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final mm = h > 0 ? m.toString().padLeft(2, '0') : m.toString();
    final out = h > 0 ? '$h:$mm:${s.toString().padLeft(2, '0')}' : '$mm:${s.toString().padLeft(2, '0')}';
    return eastern ? toEastern(out) : out;
  }
}

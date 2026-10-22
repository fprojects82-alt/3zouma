import 'numerals.dart';

/// Normalises spoken or typed text so Arabic and English can be matched
/// reliably: lower case, Western digits, no Arabic diacritics or tatweel,
/// and one spelling for letters people write in several ways.
String normalizeText(String input) {
  var s = Numerals.toWestern(input.toLowerCase());
  // Diacritics (harakat), superscript alef and tatweel.
  s = s.replaceAll(RegExp('[ً-ْٰـ]'), '');
  s = s
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  s = s.replaceAll(RegExp(r'[^\p{L}\p{N}\s:.\-]', unicode: true), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}
